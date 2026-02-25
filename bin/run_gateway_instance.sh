#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ocw-lib.sh"

NAME="${1:-}"
[[ -n "$NAME" ]] || die "Usage: $0 <gw_name>"

BOTROOT="${OPENCLAWS_HOME:-$HOME/openclaws}/gateways/${NAME}"
ENVFILE="${BOTROOT}/gateway.env"

[[ -s "$ENVFILE" ]] || die "missing env: $ENVFILE"

load_env_file "$ENVFILE"

: "${OPENCLAW_GATEWAY_WS_PORT:?Missing OPENCLAW_GATEWAY_WS_PORT in $ENVFILE}"

CFG="${OPENCLAW_CONFIG_PATH:-${BOTROOT}/.openclaw/openclaw.json}"
[[ -s "$CFG" ]] || die "missing config: $CFG"

TOKEN="$(read_gateway_token "$CFG")"
[[ -n "$TOKEN" ]] || die "Failed to read token from $CFG"

BIND="${OPENCLAW_GATEWAY_BIND:-loopback}"
WSLOG="${OPENCLAW_WS_LOG:-auto}"

export BOTROOT
export HOME="$BOTROOT"
export XDG_CONFIG_HOME="$BOTROOT/config"
export XDG_STATE_HOME="$BOTROOT/state"
export XDG_CACHE_HOME="$BOTROOT/state/cache"
export OPENCLAW_LOG_DIR="$BOTROOT/logs"
export OPENCLAW_RUN_DIR="$BOTROOT/run"
export OPENCLAW_STATE_DIR="$BOTROOT/.openclaw"
export OPENCLAW_CONFIG_PATH="$CFG"

ensure_dirs "$OPENCLAW_LOG_DIR" "$OPENCLAW_RUN_DIR"

exec openclaw gateway run \
  --port "$OPENCLAW_GATEWAY_WS_PORT" \
  --token "$TOKEN" \
  --bind "$BIND" \
  --ws-log "$WSLOG" \
  --force
