#!/bin/bash

set -euo pipefail

: "${EGRESS_LOG_DIR:?Error: EGRESS_LOG_DIR is not set}"
: "${MINIO_REGION:?Error: MINIO_REGION is not set}"
: "${MINIO_ACCESS_KEY:?Error: MINIO_ACCESS_KEY is not set}"
: "${MINIO_SECRET_KEY:?Error: MINIO_SECRET_KEY is not set}"
: "${MINIO_BUCKET:?Error: MINIO_BUCKET is not set}"

ROOM_ID="${1:-}"
[ -z "$ROOM_ID" ] && { echo "usage: $0 <ROOM_ID>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
MINIO_URL="http://minio-livekit:9000"
LOG_FILE="${EGRESS_LOG_DIR}/egress_room_${ROOM_ID}.log"
START_TS=$(date +%s.%3N)

mkdir -p "$EGRESS_LOG_DIR"

BASE_PATH="${START_TS}__${ROOM_ID}"
EGRESS_JSON="/tmp/${BASE_PATH}.json"
FILENAME="${BASE_PATH}.mp4"

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

EGRESS_ID=$(
  lk egress start --type room-composite --url "$LIVEKIT_URL" "$EGRESS_JSON" \
  | sed -n 's/.*\(EG_[A-Za-z0-9]\+\).*/\1/p' | head -n 1
)
[ -z "$EGRESS_ID" ] && { echo "Error: failed to parse egress_id"; exit 1; }

echo "$EGRESS_ID" >> "$LOG_FILE"
