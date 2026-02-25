#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ocw-lib.sh"

# Usage:
#   /opt/openclaws/bin/create_node.sh --name gw_chatgpt-1 --gateway gw_chatgpt [--host 127.0.0.1] [--display-name "..."]
#
# Policy:
# - gateway token은 저장하지 않음 (실행 시 gateway config에서 읽어 주입)
# - node-id는 node.env에 영구 저장 (절대 안 꼬이게)
# - node 상태/페어링은 NODEDIR/.openclaw 등에 저장됨

ROOT="${OPENCLAWS_HOME:-$HOME/openclaws}"
NODE_NAME=""
GW_NAME=""
GW_HOST="127.0.0.1"
DISPLAY_NAME=""

usage(){ sed -n '1,220p' "$0"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2;;
    --name) NODE_NAME="${2:-}"; shift 2;;
    --gateway|--gw) GW_NAME="${2:-}"; shift 2;;
    --host) GW_HOST="${2:-}"; shift 2;;
    --display-name) DISPLAY_NAME="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

[[ -n "$NODE_NAME" ]] || die "--name is required"
[[ -n "$GW_NAME" ]] || die "--gateway is required"

GW_BOTROOT="${ROOT}/gateways/${GW_NAME}"
GW_ENV="${GW_BOTROOT}/gateway.env"
[[ -s "$GW_ENV" ]] || die "gateway.env not found: $GW_ENV (run create_gateway.sh first)"

load_env_file "$GW_ENV"
: "${OPENCLAW_GATEWAY_WS_PORT:?Missing OPENCLAW_GATEWAY_WS_PORT in $GW_ENV}"
: "${OPENCLAW_CONFIG_PATH:?Missing OPENCLAW_CONFIG_PATH in $GW_ENV}"

GW_PORT="$OPENCLAW_GATEWAY_WS_PORT"
GW_CFG="$OPENCLAW_CONFIG_PATH"

[[ "$GW_PORT" =~ ^[0-9]+$ ]] || die "OPENCLAW_GATEWAY_WS_PORT not numeric: $GW_PORT"
[[ -s "$GW_CFG" ]] || die "gateway openclaw.json not found: $GW_CFG"

NODEDIR="${ROOT}/nodes/${NODE_NAME}"
NODE_ENV="${NODEDIR}/node.env"

if command -v sudo >/dev/null 2>&1; then
  sudo mkdir -p "$NODEDIR"
  sudo chown -R "$USER:$USER" "$NODEDIR"
fi

ensure_dirs "$NODEDIR/logs" "$NODEDIR/run" "$NODEDIR/state/cache" "$NODEDIR/config"

[[ -n "$DISPLAY_NAME" ]] || DISPLAY_NAME="$NODE_NAME"

# node-id는 "한 번 만들면 유지"
need_cmd uuidgen
NODE_ID=""
if [[ -f "$NODE_ENV" ]]; then
  NODE_ID="$(grep -E '^OPENCLAW_NODE_ID=' "$NODE_ENV" | head -n1 | cut -d= -f2- | tr -d '[:space:]' || true)"
fi
if [[ -z "$NODE_ID" ]]; then
  NODE_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
fi

# token은 저장하지 않는다. gateway config path만 저장(실행 시 token 읽기).
{
  printf 'OPENCLAW_GATEWAY_NAME=%s\n' "$GW_NAME"
  printf 'OPENCLAW_GATEWAY_HOST=%s\n' "$GW_HOST"
  printf 'OPENCLAW_GATEWAY_PORT=%s\n' "$GW_PORT"
  printf 'OPENCLAW_GATEWAY_CONFIG_PATH=%s\n' "$GW_CFG"
  printf 'OPENCLAW_NODE_DISPLAY_NAME=%s\n' "$DISPLAY_NAME"
  printf 'OPENCLAW_NODE_ID=%s\n' "$NODE_ID"
} > "$NODE_ENV"
chmod 600 "$NODE_ENV"

# 검증(가벼운)
if grep -nE $'[\r]' "$NODE_ENV" >/dev/null 2>&1; then
  die "node.env contains CRLF (^M): $NODE_ENV"
fi
if grep -nE '^\s*export\s+' "$NODE_ENV" >/dev/null 2>&1; then
  die "node.env must not contain 'export': $NODE_ENV"
fi
grep -q '^OPENCLAW_NODE_ID=' "$NODE_ENV" || die "node.env missing OPENCLAW_NODE_ID"

echo
echo "✅ Node created/updated:"
echo "  Name     : $NODE_NAME"
echo "  NodeDir  : $NODEDIR"
echo "  Env      : $NODE_ENV"
echo "  Gateway  : $GW_NAME (${GW_HOST}:${GW_PORT})"
echo "  GwConfig : $GW_CFG"
echo "  Display  : $DISPLAY_NAME"
echo "  NodeId   : $NODE_ID"
