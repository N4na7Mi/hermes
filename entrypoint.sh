#!/bin/sh
set -eu

export HOME="${HOME:-/home/agent}"
export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
export HERMES_BIN="${HERMES_BIN:-/opt/hermes/.venv/bin/hermes}"
export PORT="${PORT:-9119}"
export UPSTREAM="${UPSTREAM:-http://127.0.0.1:8642}"

mkdir -p "$HERMES_HOME" "$HOME/.hermes-web-ui"

exec node /app/dist/server/index.js
