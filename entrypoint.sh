#!/bin/sh
set -eu

PROXY_PORT="${PROXY_PORT:-9119}"
DASHBOARD_HOST="${DASHBOARD_HOST:-127.0.0.1}"
DASHBOARD_PORT="${DASHBOARD_PORT:-9120}"

hermes dashboard --host "$DASHBOARD_HOST" --port "$DASHBOARD_PORT" &
exec uvicorn login_proxy:app --host 0.0.0.0 --port "$PROXY_PORT" --app-dir /
