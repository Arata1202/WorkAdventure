#!/bin/bash

set -euo pipefail

: "${MINIO_REGION:?Error: MINIO_REGION is not set}"
: "${MINIO_ACCESS_KEY:?Error: MINIO_ACCESS_KEY is not set}"
: "${MINIO_SECRET_KEY:?Error: MINIO_SECRET_KEY is not set}"
: "${MINIO_BUCKET:?Error: MINIO_BUCKET is not set}"

ROOM_ID="${1:-}"
TRACK_ID="${2:-}"
MEETING_DATE="${3:-$(date +%Y年%-m月%-d日)}"
MEETING_TIME="${4:-$(date +%-H時%-M分%-S秒)}"
TRACK_TIME="${5:-$(date +%-H時%-M分%-S秒)}"
SPEAKER_NAME="${6:-unknown_speaker}"
[ -z "$ROOM_ID" ] || [ -z "$TRACK_ID" ] && { echo "usage: $0 <ROOM_ID> <TRACK_ID> [MEETING_DATE] [MEETING_TIME] [TRACK_TIME] [SPEAKER_NAME]"; exit 1; }

LIVEKIT_URL="${LIVEKIT_URL:-http://localhost:7880}"
MINIO_URL="${MINIO_URL:-http://minio-livekit:9000}"
START_TS=$(date +%s.%3N)

if lk egress list --url "$LIVEKIT_URL" --json 2>/dev/null \
  | sed -n '/^[\[{n]/,$p' \
  | jq -e --arg room "$ROOM_ID" --arg track "$TRACK_ID" '
      (. // [])
      | any(
          (.room_name == $room)
          and (.Request.Track != null)
          and (
            (.Request.Track.track_id? // .Request.Track.trackId? // .Request.Track.TrackId? // .Request.Track.track_sid? // .Request.Track.trackSid? // .Request.Track.TrackSid? // "") == $track
          )
          and (.status == 1 or .status == 2)
        )
    ' >/dev/null; then
  echo "WARN: already running for room: $ROOM_ID track: $TRACK_ID" >&2
  exit 0
fi

BASE_PATH="${START_TS}_${ROOM_ID}"
EGRESS_JSON="/tmp/${BASE_PATH}.json"
ROOM_LABEL="$ROOM_ID"
if [[ "$ROOM_ID" =~ ^localWorld\.[^-]+-(.+)$ ]]; then
  ROOM_LABEL="${BASH_REMATCH[1]}"
fi
SAFE_ROOM_ID=$(printf '%s' "$ROOM_LABEL" \
  | tr -d '\000' \
  | sed -E 's%/%_%g' \
  | sed -E 's/[[:cntrl:]]+/_/g' \
  | sed -E 's/^_+|_+$//g')
if [ -z "$SAFE_ROOM_ID" ]; then
  SAFE_ROOM_ID="unknown_room"
fi
SAFE_SPEAKER_NAME=$(printf '%s' "$SPEAKER_NAME" \
  | tr -d '\000' \
  | sed -E 's%/%_%g' \
  | sed -E 's/[[:cntrl:]]+/_/g' \
  | sed -E 's/^_+|_+$//g')
if [ -z "$SAFE_SPEAKER_NAME" ]; then
  SAFE_SPEAKER_NAME="unknown_speaker"
fi
FILENAME="${MEETING_DATE}/${SAFE_ROOM_ID}/${MEETING_TIME}/${SAFE_SPEAKER_NAME}/${TRACK_TIME}_${TRACK_ID}.ogg"

trap 'rm -f "$EGRESS_JSON"' EXIT

jq -n \
  --arg room "$ROOM_ID" \
  --arg track_id "$TRACK_ID" \
  --arg filename "$FILENAME" \
  --arg region "$MINIO_REGION" \
  --arg access_key "$MINIO_ACCESS_KEY" \
  --arg secret "$MINIO_SECRET_KEY" \
  --arg bucket "$MINIO_BUCKET" \
  --arg endpoint "$MINIO_URL" \
  '{
    room_name: $room,
    track_id: $track_id,
    file: {
      filepath: $filename,
      disable_manifest: true,
      s3: {
        region: $region,
        access_key: $access_key,
        secret: $secret,
        bucket: $bucket,
        endpoint: $endpoint,
        force_path_style: true
      }
    }
  }' > "$EGRESS_JSON"

MAX_RETRIES=5
RETRY_DELAY_SECONDS="0.5"

attempt=1
delay="$RETRY_DELAY_SECONDS"
while true; do
  output=""
  if output=$(lk egress start --type track --url "$LIVEKIT_URL" "$EGRESS_JSON" 2>&1); then
    echo "$output"
    break
  fi
  rc=$?

  if echo "$output" | grep -qiE 'twirp error unavailable|no response from servers|context deadline exceeded|timeout'; then
    if [ "$attempt" -ge "$MAX_RETRIES" ]; then
      echo "$output" >&2
      exit "$rc"
    fi

    jitter_ms=$((RANDOM % 200))
    jitter=$(awk -v ms="$jitter_ms" 'BEGIN{printf "%.3f", ms/1000}')
    sleep_for=$(awk -v d="$delay" -v j="$jitter" 'BEGIN{printf "%.3f", d + j}')

    echo "WARN: lk egress start failed (attempt ${attempt}/${MAX_RETRIES}) for room: ${ROOM_ID}; retrying in ${sleep_for}s" >&2
    echo "$output" >&2
    sleep "$sleep_for"

    attempt=$((attempt + 1))
    delay=$(awk -v d="$delay" 'BEGIN{d*=2; if(d>10)d=10; printf "%.3f", d}')
    continue
  fi

  echo "$output" >&2
  exit "$rc"
done
