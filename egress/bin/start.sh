#!/bin/bash

set -eu

ROOM="${1:-}"
[ -z "$ROOM" ] && { echo "usage: $0 <ROOM>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
MEETING_TS=$(date +%s.%3N)
OUT="./out/${MEETING_TS}__${ROOM}"
LOG_DIR="./egress/logs"
LOG="${LOG_DIR}/egress_${ROOM}.log"
STARTED="/tmp/egress_started_${ROOM}_${MEETING_TS}.txt"

mkdir -p "$OUT" "$LOG_DIR"
: > "$STARTED"

TOKEN=$(
  dotenvx run -- lk --curl room participants list \
    --url "$LIVEKIT_URL" "$ROOM" \
  | sed -n "s/.*Authorization: Bearer \([^']*\).*/\1/p"
)
[ -z "$TOKEN" ] && { echo "Error: failed to get token"; exit 1; }

while :; do
  RESP=$(
    curl -sS -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"room\":\"$ROOM\"}" \
      "$LIVEKIT_URL/twirp/livekit.RoomService/ListParticipants" \
    || true
  )

  if [ -z "${RESP:-}" ]; then
    echo "warn: ListParticipants failed (empty response)" >> "$LOG"
    sleep 1
    continue
  fi

  PARTICIPANT_COUNT=$(echo "$RESP" | jq -r '.participants | length' 2>/dev/null || echo "0")
  [ "$PARTICIPANT_COUNT" = "0" ] && { echo "room empty; exit" >> "$LOG"; exit 0; }

  TRACK_IDS=$(echo "$RESP" | jq -r '
    .participants[]
    | .name as $id
    | (.tracks[]? | select(.type=="AUDIO" or .type=="audio") | [$id, .sid] | @tsv)
  ' 2>/dev/null || true)

  if [ -n "${TRACK_IDS:-}" ]; then
    echo "$TRACK_IDS" | while IFS=$'\t' read -r IDENTITY TRACK_ID; do
      grep -qx "$TRACK_ID" "$STARTED" && continue

      REC_TS=$(date +%s.%3N)
      SAFE_IDENTITY=$(echo "$IDENTITY" | tr '/ :@' '____')
      JSON="/tmp/egress_track_${TRACK_ID}.json"
      FILE="$OUT/${REC_TS}__${SAFE_IDENTITY}__${TRACK_ID}.ogg"

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

      if [ -z "$EGRESS_ID" ]; then
        echo "Error: failed to parse egress_id identity=$IDENTITY track=$TRACK_ID" >> "$LOG"
        continue
      fi

      echo "$TRACK_ID" >> "$STARTED"
      echo "$EGRESS_ID $FILE $IDENTITY $TRACK_ID meeting_ts=$MEETING_TS rec_ts=$REC_TS" >> "$LOG"
      echo "started: room=$ROOM identity=$IDENTITY track=$TRACK_ID file=$FILE"
    done
  fi

  sleep 1
done
