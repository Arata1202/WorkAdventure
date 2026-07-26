#!/bin/sh

set -eu

: "${LIVEKIT_API_KEY:?Error: LIVEKIT_API_KEY is not set}"
: "${LIVEKIT_API_SECRET:?Error: LIVEKIT_API_SECRET is not set}"

if [ ! -f /tmp/livekit-config.yaml ] || [ /etc/livekit/livekit-config.template.yaml -nt /tmp/livekit-config.yaml ]; then
  echo "Generating livekit-config.yaml from livekit-config.template.yaml..."
  sed \
    -e "s|\${LIVEKIT_API_KEY}|$LIVEKIT_API_KEY|g" \
    -e "s|\${LIVEKIT_API_SECRET}|$LIVEKIT_API_SECRET|g" \
    /etc/livekit/livekit-config.template.yaml > /tmp/livekit-config.yaml
fi

exec /livekit-server --config /tmp/livekit-config.yaml
