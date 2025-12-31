#!/bin/sh

set -eu

: "${DOMAIN:?Error: DOMAIN is not set}"
: "${MATRIX_REGISTRATION_SHARED_SECRET:?Error: MATRIX_REGISTRATION_SHARED_SECRET is not set}"
: "${MATRIX_MACAROON_SECRET_KEY:?Error: MATRIX_MACAROON_SECRET_KEY is not set}"
: "${MATRIX_FORM_SECRET:?Error: MATRIX_FORM_SECRET is not set}"
: "${MYSQL_DATABASE:?Error: MYSQL_DATABASE is not set}"
: "${MYSQL_USER:?Error: MYSQL_USER is not set}"
: "${MYSQL_PASSWORD:?Error: MYSQL_PASSWORD is not set}"
: "${OPENID_CLIENT_ID:?Error: OPENID_CLIENT_ID is not set}"
: "${OPENID_CLIENT_SECRET:?Error: OPENID_CLIENT_SECRET is not set}"

if [ ! -f /data/homeserver.yaml ] || [ /homeserver.template.yaml -nt /data/homeserver.yaml ]; then
  echo "Generating homeserver.yaml from homeserver.template.yaml..."
  sed \
    -e "s|\${DOMAIN}|$DOMAIN|g" \
    -e "s|\${MATRIX_REGISTRATION_SHARED_SECRET}|$MATRIX_REGISTRATION_SHARED_SECRET|g" \
    -e "s|\${MATRIX_MACAROON_SECRET_KEY}|$MATRIX_MACAROON_SECRET_KEY|g" \
    -e "s|\${MATRIX_FORM_SECRET}|$MATRIX_FORM_SECRET|g" \
    -e "s|\${MYSQL_DATABASE}|$MYSQL_DATABASE|g" \
    -e "s|\${MYSQL_USER}|$MYSQL_USER|g" \
    -e "s|\${MYSQL_PASSWORD}|$MYSQL_PASSWORD|g" \
    -e "s|\${OPENID_CLIENT_ID}|$OPENID_CLIENT_ID|g" \
    -e "s|\${OPENID_CLIENT_SECRET}|$OPENID_CLIENT_SECRET|g" \
    /homeserver.template.yaml > /data/homeserver.yaml
fi

exec /start.py
