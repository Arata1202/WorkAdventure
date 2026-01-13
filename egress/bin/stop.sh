#!/bin/bash

set -euo pipefail

ROOM_ID="${1:-}"
[ -z "$ROOM_ID" ] && { echo "usage: $0 <ROOM_ID>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
LOG_DIR="./egress/logs"
LOG_FILE="${LOG_DIR}/egress_room_${ROOM_ID}.log"
[ ! -f "$LOG_FILE" ] && { echo "Error: no log found: $LOG_FILE"; exit 1; }

while read -r EGRESS_ID; do
  lk egress stop --url "$LIVEKIT_URL" --id "$EGRESS_ID" || true
done < <(sort -u "$LOG_FILE")
