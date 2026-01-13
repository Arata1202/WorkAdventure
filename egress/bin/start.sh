#!/bin/bash

set -euo pipefail

ROOM_ID="${1:-}"
[ -z "$ROOM_ID" ] && { echo "usage: $0 <ROOM_ID>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
OUT_DIR="./out"
LOG_DIR="./egress/logs"
LOG_FILE="${LOG_DIR}/egress_room_${ROOM_ID}.log"
START_TS=$(date +%s.%3N)

mkdir -p "$OUT_DIR" "$LOG_DIR"

ACCESS_TOKEN=$(
  lk --curl room participants list \
    --url "$LIVEKIT_URL" "$ROOM_ID" \
  | sed -n "s/.*Authorization: Bearer \([^']*\).*/\1/p"
)
[ -z "$ACCESS_TOKEN" ] && { echo "Error: failed to get token"; exit 1; }

AUDIO_TRACKS=$(
  curl -sS -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"room\":\"$ROOM_ID\"}" \
    "$LIVEKIT_URL/twirp/livekit.RoomService/ListParticipants" \
  | jq -r '.participants[]
           | .identity as $identity
           | .name as $name
           | (.tracks[]?
           | select(.type=="AUDIO")
           | [$identity, $name, .sid]
           | @tsv)'
)
[ -z "$AUDIO_TRACKS" ] && { echo "Error: No audio tracks"; exit 1; }

while IFS=$'\t' read -r IDENTITY PARTICIPANT_NAME TRACK_ID; do
  EGRESS_JSON="/tmp/egress_track_${TRACK_ID}.json"
  BASE_PATH="$OUT_DIR/${START_TS}__${ROOM_ID}__${TRACK_ID}"
  REC_OGG="${BASE_PATH}.ogg"
  REC_JSON="${BASE_PATH}.json"

  jq -n \
    --arg room "$ROOM_ID" \
    --arg track_id "$TRACK_ID" \
    --arg filepath "$REC_OGG" \
    '{
      room_name: $room,
      track_id: $track_id,
      file: { filepath: $filepath }
    }' > "$EGRESS_JSON"

  EGRESS_ID=$(
    lk egress start --type track --url "$LIVEKIT_URL" "$EGRESS_JSON" \
    | sed -n 's/.*\(EG_[A-Za-z0-9]\+\).*/\1/p' | head -n 1
  )
  [ -z "$EGRESS_ID" ] && { echo "Error: failed to parse egress_id"; exit 1; }

  echo "$EGRESS_ID" >> "$LOG_FILE"

  jq -n \
    --arg start_ts "$START_TS" \
    --arg room "$ROOM_ID" \
    --arg track_id "$TRACK_ID" \
    --arg identity "$IDENTITY" \
    --arg participant_name "$PARTICIPANT_NAME" \
    '{start_ts:$start_ts, room:$room, track_id:$track_id, identity:$identity, participant_name:$participant_name}' > "$REC_JSON"

done <<< "$AUDIO_TRACKS"
