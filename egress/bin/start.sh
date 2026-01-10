#!/bin/bash

set -eu

ROOM="${1:-}"
[ -z "$ROOM" ] && { echo "usage: $0 <ROOM>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
OUT="./out"
JSON="/tmp/egress_room_mix.json"
FILE="$OUT/${ROOM}_$(date +%s).mp4"
LOG_DIR="./logs"

mkdir -p "$LOG_DIR"

TOKEN=$(
  dotenvx run -- lk --curl room participants list \
    --url "$LIVEKIT_URL" "$ROOM" \
  | sed -n "s/.*Authorization: Bearer \([^']*\).*/\1/p"
)
[ -z "$TOKEN" ] && { echo "Error: failed to get token"; exit 1; }

cat > "$JSON" <<EOF
{
  "room_name": "$ROOM",
  "audio_only": true,
  "file": { "filepath": "$FILE" }
}
EOF

EGRESS_ID=$(
  dotenvx run -- lk egress start --type room --url "$LIVEKIT_URL" --output json "$JSON" \
  | jq -r '.egress_id // .egressId // empty'
)
[ -z "$EGRESS_ID" ] && { echo "Error: failed to parse egress_id"; exit 1; }

echo "$EGRESS_ID $FILE" >> "${LOG_DIR}/egress_${ROOM}.log"

echo "started: room=$ROOM file=$FILE"
