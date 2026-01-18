#!/bin/bash

set -euo pipefail

: "${MINIO_REGION:?Error: MINIO_REGION is not set}"
: "${MINIO_ACCESS_KEY:?Error: MINIO_ACCESS_KEY is not set}"
: "${MINIO_SECRET_KEY:?Error: MINIO_SECRET_KEY is not set}"
: "${MINIO_BUCKET:?Error: MINIO_BUCKET is not set}"

ROOM_ID="${1:-}"
[ -z "$ROOM_ID" ] && { echo "usage: $0 <ROOM_ID>"; exit 1; }

LIVEKIT_URL="${LIVEKIT_URL:-http://localhost:7880}"
MINIO_URL="${MINIO_URL:-http://minio-livekit:9000}"
START_TS=$(date +%s.%3N)

if lk egress list --url "$LIVEKIT_URL" --json 2>/dev/null \
  | sed -n '/^[\[{n]/,$p' \
  | jq -e --arg room "$ROOM_ID" '
      (. // [])
      | any(
          (.room_name == $room)
          and (.Request.RoomComposite != null)
          and (.status == 1 or .status == 2)
        )
    ' >/dev/null; then
  echo "WARN: already running for room: $ROOM_ID" >&2
  exit 0
fi

BASE_PATH="${START_TS}_${ROOM_ID}"
EGRESS_JSON="/tmp/${BASE_PATH}.json"
ROOM_NAME=$(echo "$ROOM_ID" | sed -E 's/.*-([^-]+)$/\1/')
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H-%M-%S)
FILENAME="${DATE}/${ROOM_NAME}/${TIME}.ogg"

trap 'rm -f "$EGRESS_JSON"' EXIT

jq -n \
  --arg room "$ROOM_ID" \
  --arg filename "$FILENAME" \
  --arg region "$MINIO_REGION" \
  --arg access_key "$MINIO_ACCESS_KEY" \
  --arg secret "$MINIO_SECRET_KEY" \
  --arg bucket "$MINIO_BUCKET" \
  --arg endpoint "$MINIO_URL" \
  '{
    room_name: $room,
    audio_only: true,
    file: {
      filepath: $filename,
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
  if output=$(lk egress start --type room-composite --url "$LIVEKIT_URL" "$EGRESS_JSON" 2>&1); then
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
