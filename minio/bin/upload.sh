#!/bin/bash

set -euo pipefail

: "${EGRESS_OUT_DIR:?Error: EGRESS_OUT_DIR is not set}"
: "${EGRESS_LOG_DIR:?Error: EGRESS_LOG_DIR is not set}"
: "${MINIO_ACCESS_KEY:?Error: MINIO_ACCESS_KEY is not set}"
: "${MINIO_SECRET_KEY:?Error: MINIO_SECRET_KEY is not set}"
: "${MINIO_ALIAS:?Error: MINIO_ALIAS is not set}"
: "${MINIO_BUCKET:?Error: MINIO_BUCKET is not set}"

MINIO_URL="http://minio-livekit:9000"

[ ! -d "$EGRESS_OUT_DIR" ] && { echo "Error: no out dir: $EGRESS_OUT_DIR"; exit 1; }

if ! mc alias list | awk '{print $1}' | grep -qx "$MINIO_ALIAS"; then
  mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"
fi

if ! mc ls "${MINIO_ALIAS}/${MINIO_BUCKET}" >/dev/null 2>&1; then
  mc mb "${MINIO_ALIAS}/${MINIO_BUCKET}"
fi

while read -r REC_FILES; do
  BASENAME=$(basename "$REC_FILES")
  mc cp "$REC_FILES" "${MINIO_ALIAS}/${MINIO_BUCKET}/${BASENAME}"
done < <(
  find "$EGRESS_OUT_DIR" -maxdepth 1 -type f \
  \( -name "*.ogg" -o -name "*.json" \)
)
