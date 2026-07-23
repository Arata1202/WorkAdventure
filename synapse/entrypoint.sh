#!/bin/sh

set -eu

: "${DOMAIN:?Error: DOMAIN is not set}"
: "${MATRIX_REGISTRATION_SHARED_SECRET:?Error: MATRIX_REGISTRATION_SHARED_SECRET is not set}"
: "${MATRIX_MACAROON_SECRET_KEY:?Error: MATRIX_MACAROON_SECRET_KEY is not set}"
: "${MATRIX_FORM_SECRET:?Error: MATRIX_FORM_SECRET is not set}"
: "${POSTGRES_DB:?Error: POSTGRES_DB is not set}"
: "${POSTGRES_USER:?Error: POSTGRES_USER is not set}"
: "${POSTGRES_PASSWORD:?Error: POSTGRES_PASSWORD is not set}"
: "${OPENID_IDP_ID:?Error: OPENID_IDP_ID is not set}"
: "${OPENID_IDP_NAME:?Error: OPENID_IDP_NAME is not set}"
: "${OPENID_CLIENT_ID:?Error: OPENID_CLIENT_ID is not set}"
: "${OPENID_CLIENT_SECRET:?Error: OPENID_CLIENT_SECRET is not set}"
: "${OPENID_CLIENT_ISSUER:?Error: OPENID_CLIENT_ISSUER is not set}"
: "${OPENID_USERNAME_CLAIM:?Error: OPENID_USERNAME_CLAIM is not set}"

if [ ! -f /data/homeserver.yaml ] || [ /homeserver.template.yaml -nt /data/homeserver.yaml ]; then
  echo "Generating homeserver.yaml from homeserver.template.yaml..."
  sed \
    -e "s|\${DOMAIN}|$DOMAIN|g" \
    -e "s|\${MATRIX_REGISTRATION_SHARED_SECRET}|$MATRIX_REGISTRATION_SHARED_SECRET|g" \
    -e "s|\${MATRIX_MACAROON_SECRET_KEY}|$MATRIX_MACAROON_SECRET_KEY|g" \
    -e "s|\${MATRIX_FORM_SECRET}|$MATRIX_FORM_SECRET|g" \
    -e "s|\${POSTGRES_DB}|$POSTGRES_DB|g" \
    -e "s|\${POSTGRES_USER}|$POSTGRES_USER|g" \
    -e "s|\${POSTGRES_PASSWORD}|$POSTGRES_PASSWORD|g" \
    -e "s|\${OPENID_IDP_ID}|$OPENID_IDP_ID|g" \
    -e "s|\${OPENID_IDP_NAME}|$OPENID_IDP_NAME|g" \
    -e "s|\${OPENID_CLIENT_ID}|$OPENID_CLIENT_ID|g" \
    -e "s|\${OPENID_CLIENT_SECRET}|$OPENID_CLIENT_SECRET|g" \
    -e "s|\${OPENID_CLIENT_ISSUER}|$OPENID_CLIENT_ISSUER|g" \
    -e "s|\${OPENID_USERNAME_CLAIM}|$OPENID_USERNAME_CLAIM|g" \
    /homeserver.template.yaml > /data/homeserver.yaml
fi

if [ ! -f /data/log.config.yaml ] || [ /log.config.yaml -nt /data/log.config.yaml ]; then
  echo "Copying log.config.yaml..."
  cp /log.config.yaml /data/log.config.yaml
fi

exec /start.py
