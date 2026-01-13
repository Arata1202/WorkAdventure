#!/bin/bash

set -euo pipefail

: "${MINIO_ACCESS_KEY:?Error: MINIO_ACCESS_KEY is not set}"
: "${MINIO_SECRET_KEY:?Error: MINIO_SECRET_KEY is not set}"

OUT_DIR="./out"
MINIO_ALIAS="minio"
MINIO_URL="http://localhost:9000"
MINIO_BUCKET="livekit-recording"

[ ! -d "$OUT_DIR" ] && { echo "Error: no out dir: $OUT_DIR"; exit 1; }

if ! mc alias list | awk '{print $1}' | grep -qx "$MINIO_ALIAS"; then
  mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"
fi

if ! mc ls "${MINIO_ALIAS}/${MINIO_BUCKET}" >/dev/null 2>&1; then
  mc mb "${MINIO_ALIAS}/${MINIO_BUCKET}"
fi

while read -r REC_FILES; do
  BASENAME=$(basename "$REC_FILES")
  mc cp --overwrite "$REC_FILES" "${MINIO_ALIAS}/${MINIO_BUCKET}/${BASENAME}"
done < <(
  find "$OUT_DIR" -maxdepth 1 -type f \
  \( -name "*.ogg" -o -name "*.json" \)
)
