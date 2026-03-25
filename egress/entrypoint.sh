#!/bin/sh

set -eu

: "${LIVEKIT_API_KEY:?Error: LIVEKIT_API_KEY is not set}"
: "${LIVEKIT_API_SECRET:?Error: LIVEKIT_API_SECRET is not set}"

if [ ! -f /tmp/egress-config.yaml ] || [ /etc/egress/egress-config.template.yaml -nt /tmp/egress-config.yaml ]; then
    echo "Generating egress-config.yaml from egress-config.template.yaml..."
    sed \
      -e "s|\${LIVEKIT_API_KEY}|$LIVEKIT_API_KEY|g" \
      -e "s|\${LIVEKIT_API_SECRET}|$LIVEKIT_API_SECRET|g" \
      /etc/egress/egress-config.template.yaml > /tmp/egress-config.yaml
fi

# Start PulseAudio daemon (required for RoomCompositeEgress audio recording)
pulseaudio --kill >/dev/null 2>&1 || true
rm -rf /tmp/pulse-* /home/egress/.cache/xdgr/pulse/ >/dev/null 2>&1 || true
pulseaudio -D --verbose --exit-idle-time=-1 --disallow-exit

exec /bin/egress --config /tmp/egress-config.yaml
