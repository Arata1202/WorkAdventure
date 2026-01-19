#!/bin/sh

set -eu

: "${LIVEKIT_API_KEY:?Error: LIVEKIT_API_KEY is not set}"
: "${LIVEKIT_API_SECRET:?Error: LIVEKIT_API_SECRET is not set}"

if [ ! -f /tmp/egress-config.yaml ] || [ /etc/egress/egress-config.template.yaml -nt /tmp/egress-config.yaml ]; then
    echo "Generating egress-config.yaml from egress-config.template.yaml..."
    sed \
      -e "s|\${LIVEKIT_API_KEY}|$LIVEKIT_API_KEY|g" \
      -e "s|\${LIVEKIT_API_SECRET}|$LIVEKIT_API_SECRET|g" \
      -e "s|\${MINIO_REGION}|$MINIO_REGION|g" \
      -e "s|\${MINIO_ACCESS_KEY}|$MINIO_ACCESS_KEY|g" \
      -e "s|\${MINIO_SECRET_KEY}|$MINIO_SECRET_KEY|g" \
      -e "s|\${MINIO_BUCKET}|$MINIO_BUCKET|g" \
      /etc/egress/egress-config.template.yaml > /tmp/egress-config.yaml
fi

exec /bin/egress --config /tmp/egress-config.yaml
