#!/bin/sh
set -eu

PROXY_PORT="${PROXY_PORT:-9119}"
DASHBOARD_HOST="${DASHBOARD_HOST:-127.0.0.1}"
DASHBOARD_PORT="${DASHBOARD_PORT:-9120}"
BASIC_AUTH_USER="${BASIC_AUTH_USER:-admin}"
BASIC_AUTH_PASSWORD="${BASIC_AUTH_PASSWORD:-change-me-now}"

PASSWORD_HASH="$(caddy hash-password --plaintext "$BASIC_AUTH_PASSWORD")"

mkdir -p /etc/caddy
cat >/etc/caddy/Caddyfile <<EOF
:${PROXY_PORT} {
    basic_auth {
        ${BASIC_AUTH_USER} ${PASSWORD_HASH}
    }

    reverse_proxy 127.0.0.1:${DASHBOARD_PORT}
}
EOF

hermes dashboard --host "$DASHBOARD_HOST" --port "$DASHBOARD_PORT" &
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
