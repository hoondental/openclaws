#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ocw-lib.sh"

NAME="${1:-}"
shift || true
[[ -n "$NAME" ]] || die "Usage: $0 <node_name> [--reset-device] [--rotate-node-id]"

RESET_DEVICE=0
ROTATE_NODE_ID=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reset-device) RESET_DEVICE=1; shift;;
    --rotate-node-id) ROTATE_NODE_ID=1; shift;;
    -h|--help)
      echo "Usage: $0 <node_name> [--reset-device] [--rotate-node-id]"
      echo "  --reset-device    wipe node local identity/cache (.openclaw + state + config)"
      echo "  --rotate-node-id  generate new OPENCLAW_NODE_ID in node.env (treat as new node)"
      exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

ROOT="${OPENCLAWS_HOME:-$HOME/openclaws}"
NODEDIR="${ROOT}/nodes/${NAME}"
ENVFILE="${NODEDIR}/node.env"
[[ -s "$ENVFILE" ]] || die "missing node env: $ENVFILE"

load_env_file "$ENVFILE"

: "${OPENCLAW_GATEWAY_HOST:?Missing OPENCLAW_GATEWAY_HOST}"
: "${OPENCLAW_GATEWAY_PORT:?Missing OPENCLAW_GATEWAY_PORT}"
: "${OPENCLAW_GATEWAY_CONFIG_PATH:?Missing OPENCLAW_GATEWAY_CONFIG_PATH}"
: "${OPENCLAW_NODE_ID:?Missing OPENCLAW_NODE_ID}"

[[ "$OPENCLAW_GATEWAY_PORT" =~ ^[0-9]+$ ]] || die "OPENCLAW_GATEWAY_PORT not numeric: $OPENCLAW_GATEWAY_PORT"
GWCFG="$OPENCLAW_GATEWAY_CONFIG_PATH"
[[ -s "$GWCFG" ]] || die "gateway config not found: $GWCFG"

# mismatch 해결용: 노드 로컬 상태를 "진짜로" 리셋
# (.openclaw 뿐 아니라 state/config에도 device/pairing이 저장될 수 있음)
if [[ $RESET_DEVICE -eq 1 ]]; then
  rm -rf "$NODEDIR/.openclaw" "$NODEDIR/state" "$NODEDIR/config"
fi

# node-id 교체(완전 새 노드로)
if [[ $ROTATE_NODE_ID -eq 1 ]]; then
  need_cmd uuidgen
  NEW_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  if grep -q '^OPENCLAW_NODE_ID=' "$ENVFILE"; then
    sed -i "s/^OPENCLAW_NODE_ID=.*/OPENCLAW_NODE_ID=${NEW_ID}/" "$ENVFILE"
  else
    printf '\nOPENCLAW_NODE_ID=%s\n' "$NEW_ID" >> "$ENVFILE"
  fi
  export OPENCLAW_NODE_ID="$NEW_ID"
fi

# 실행 시점에 gateway token 읽어서 프로세스 env로만 주입
TOKEN="$(read_gateway_token "$GWCFG")"
[[ -n "$TOKEN" ]] || die "Failed to read gateway.auth.token from: $GWCFG"
export OPENCLAW_GATEWAY_TOKEN="$TOKEN"

DISPLAY_NAME="${OPENCLAW_NODE_DISPLAY_NAME:-$NAME}"

# Node 인스턴스별 상태/로그 분리
export HOME="$NODEDIR"
export XDG_CONFIG_HOME="$NODEDIR/config"
export XDG_STATE_HOME="$NODEDIR/state"
export XDG_CACHE_HOME="$NODEDIR/state/cache"
export OPENCLAW_LOG_DIR="$NODEDIR/logs"
export OPENCLAW_RUN_DIR="$NODEDIR/run"
ensure_dirs "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$OPENCLAW_LOG_DIR" "$OPENCLAW_RUN_DIR"

OPENCLAW_CMD="${OPENCLAW_CMD:-}"
if [[ -z "$OPENCLAW_CMD" ]]; then
  if command -v openclaw >/dev/null 2>&1; then
    OPENCLAW_CMD="$(command -v openclaw)"
  elif [[ -x "$HOME/.local/bin/openclaw" ]]; then
    OPENCLAW_CMD="$HOME/.local/bin/openclaw"
  elif [[ -d "$HOME/.nvm/versions/node" ]]; then
    NVM_CANDIDATE="$(ls -1d "$HOME"/.nvm/versions/node/*/bin/openclaw 2>/dev/null | sort -V | tail -n1 || true)"
    if [[ -n "$NVM_CANDIDATE" && -x "$NVM_CANDIDATE" ]]; then
      OPENCLAW_CMD="$NVM_CANDIDATE"
    fi
  fi

  if [[ -z "$OPENCLAW_CMD" && -x "/usr/local/bin/openclaw" ]]; then
    OPENCLAW_CMD="/usr/local/bin/openclaw"
  fi
  if [[ -z "$OPENCLAW_CMD" && -x "/usr/bin/openclaw" ]]; then
    OPENCLAW_CMD="/usr/bin/openclaw"
  fi

  [[ -n "$OPENCLAW_CMD" ]] || die "openclaw executable not found. Set OPENCLAW_CMD or fix PATH for systemd user service."
fi

exec "$OPENCLAW_CMD" node run \
  --host "$OPENCLAW_GATEWAY_HOST" \
  --port "$OPENCLAW_GATEWAY_PORT" \
  --display-name "$DISPLAY_NAME" \
  --node-id "$OPENCLAW_NODE_ID"
