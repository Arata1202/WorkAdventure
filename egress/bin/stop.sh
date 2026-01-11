#!/bin/bash

set -eu

ROOM="${1:-}"
[ -z "$ROOM" ] && { echo "usage: $0 <ROOM>"; exit 1; }

LIVEKIT_URL="http://localhost:7880"
LOG="./egress/logs/egress_${ROOM}.log"
[ ! -f "$LOG" ] && { echo "Error: no log found: $LOG"; exit 1; }

awk '{print $1}' "$LOG" | while read -r EGRESS_ID; do
  dotenvx run -- lk egress stop --url "$LIVEKIT_URL" --id "$EGRESS_ID" || true
done
