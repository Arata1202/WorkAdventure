#!/bin/bash

set -eu

ROOM="${1:-}"
[ -z "$ROOM" ] && { echo "usage: $0 <ROOM>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
OUT="./out"
LOG_DIR="./logs"
LOG="${LOG_DIR}/egress_${ROOM}.log"
START_TS=$(date +%s.%3N)

mkdir -p "$OUT" "$LOG_DIR"

: > "$LOG"

TOKEN=$(
  dotenvx run -- lk --curl room participants list \
    --url "$LIVEKIT_URL" "$ROOM" \
  | sed -n "s/.*Authorization: Bearer \([^']*\).*/\1/p"
)
[ -z "$TOKEN" ] && { echo "Error: failed to get token"; exit 1; }

TRACK_IDS=$(
  curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"room\":\"$ROOM\"}" \
    "$LIVEKIT_URL/twirp/livekit.RoomService/ListParticipants" \
  | jq -r '.participants[]
           | .identity as $id
           | (.tracks[]? | select(.type=="AUDIO" or .type=="audio") | [$id, .sid] | @tsv)'
)
[ -z "$TRACK_IDS" ] && { echo "Error: No audio tracks"; exit 1; }

echo "$TRACK_IDS" | while IFS=$'\t' read -r IDENTITY TRACK_ID; do
  JSON="/tmp/egress_track_${TRACK_ID}.json"
  FILE="$OUT/${ROOM}__${IDENTITY}__${START_TS}__${TRACK_ID}.ogg"

  cat > "$JSON" <<EOF
{
  "room_name": "$ROOM",
  "track_id": "$TRACK_ID",
  "file": { "filepath": "$FILE" }
}
EOF

  EGRESS_ID=$(
    dotenvx run -- lk egress start --type track --url "$LIVEKIT_URL" "$JSON" \
    | sed -n 's/.*\(EG_[A-Za-z0-9]\+\).*/\1/p' | head -n 1
  )
  [ -z "$EGRESS_ID" ] && { echo "Error: failed to parse egress_id"; exit 1; }

  echo "$EGRESS_ID $FILE $IDENTITY $TRACK_ID $START_TS" >> "$LOG"

  echo "started: room=$ROOM identity=$IDENTITY track=$TRACK_ID file=$FILE"
done
