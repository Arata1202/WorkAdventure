#!/bin/bash

set -eu

ROOM="${1:-}"
[ -z "$ROOM" ] && { echo "usage: $0 <ROOM>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
LOG="/livekit/logs/egress_${ROOM}.log"
[ ! -f "$LOG" ] && { echo "Error: no log found: $LOG"; exit 1; }

EGRESS_ID=$(tail -n 1 "$LOG" | awk '{print $1}')
[ -z "$EGRESS_ID" ] && { echo "Error: failed to read egress id"; exit 1; }

dotenvx run -- lk egress stop --url "$LIVEKIT_URL" --id "$EGRESS_ID"
echo "stopped: room=$ROOM id=$EGRESS_ID"
