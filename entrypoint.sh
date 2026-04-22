#!/bin/sh
set -eu

export DATA_DIR="${DATA_DIR:-/data}"
export HOME="${HOME:-/home/agent}"
export HERMES_BIN="${HERMES_BIN:-/opt/hermes/.venv/bin/hermes}"
export GATEWAY_ALLOW_ALL_USERS="${GATEWAY_ALLOW_ALL_USERS:-true}"
export PORT="${PORT:-9119}"
export UPSTREAM="${UPSTREAM:-http://127.0.0.1:8642}"

mkdir -p "$DATA_DIR" "$HOME"

link_persistent_dir() {
  source_path="$1"
  target_path="$2"

  mkdir -p "$target_path"

  if [ -L "$source_path" ]; then
    return
  fi

  if [ -d "$source_path" ] && [ -z "$(ls -A "$target_path" 2>/dev/null)" ] && [ -n "$(ls -A "$source_path" 2>/dev/null)" ]; then
    cp -a "$source_path"/. "$target_path"/
  fi

  rm -rf "$source_path"
  ln -s "$target_path" "$source_path"
}

link_persistent_dir "$HOME/.hermes" "$DATA_DIR/.hermes"
link_persistent_dir "$HOME/.hermes-web-ui" "$DATA_DIR/.hermes-web-ui"

export HERMES_HOME="${HERMES_HOME:-$DATA_DIR/.hermes}"

cleanup() {
  if [ -n "${webui_pid:-}" ] && kill -0 "$webui_pid" 2>/dev/null; then
    kill "$webui_pid" 2>/dev/null || true
  fi
  if [ -n "${gateway_pid:-}" ] && kill -0 "$gateway_pid" 2>/dev/null; then
    kill "$gateway_pid" 2>/dev/null || true
  fi
  wait 2>/dev/null || true
}

trap cleanup INT TERM EXIT

"$HERMES_BIN" gateway run --replace &
gateway_pid=$!

i=0
until curl -fsS "$UPSTREAM/health" >/dev/null 2>&1; do
  i=$((i + 1))
  if ! kill -0 "$gateway_pid" 2>/dev/null; then
    echo "Gateway exited before becoming healthy." >&2
    wait "$gateway_pid"
    exit 1
  fi
  if [ "$i" -ge 60 ]; then
    echo "Gateway did not become healthy in time." >&2
    exit 1
  fi
  sleep 1
done

node /app/dist/server/index.js &
webui_pid=$!

while :; do
  if ! kill -0 "$gateway_pid" 2>/dev/null; then
    wait "$gateway_pid"
    exit 1
  fi
  if ! kill -0 "$webui_pid" 2>/dev/null; then
    wait "$webui_pid"
    exit 1
  fi
  sleep 2
done
