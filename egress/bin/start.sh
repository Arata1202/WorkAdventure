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
  | jq -Rns --arg room "$ROOM_ID" '
      (split("\n") | map(fromjson?) | map(select(. != null)) | first) as $data
      | (if ($data | type) == "array" then $data else [] end)
      | any(
          (.room_name == $room)
          and (.Request.RoomComposite != null)
          and (.status == 1 or .status == 2)
        )
    ' >/dev/null 2>/dev/null; then
  echo "WARN: already running for room: $ROOM_ID" >&2
  exit 0
fi

BASE_PATH="${START_TS}__${ROOM_ID}"
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

lk egress start --type room-composite --url "$LIVEKIT_URL" "$EGRESS_JSON"
