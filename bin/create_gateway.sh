#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ocw-lib.sh"

# create_gateway.sh
# Usage:
#   /opt/openclaws/bin/create_gateway.sh --name gw_chatgpt --ws-port 21100
# Optional:
#   --root /opt/openclaws
#   --bind loopback|lan|tailnet|auto|custom   (default: loopback)
#   --ws-log auto|full|compact               (default: auto)
#   --model <provider/model>                 (e.g. openai-codex/gpt-5.3-codex)
#   --force                                  (allow even if port is in use; not recommended)

ROOT="${OPENCLAWS_HOME:-$HOME/openclaws}"
GW_NAME=""
WS_PORT=""
BIND_MODE="loopback"
WS_LOG="auto"
MODEL_PRIMARY=""
FORCE=0

usage(){ sed -n '1,240p' "$0"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2;;
    --name) GW_NAME="${2:-}"; shift 2;;
    --ws-port|--port) WS_PORT="${2:-}"; shift 2;;
    --bind) BIND_MODE="${2:-}"; shift 2;;
    --ws-log) WS_LOG="${2:-}"; shift 2;;
    --model) MODEL_PRIMARY="${2:-}"; shift 2;;
    --force) FORCE=1; shift;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

[[ -n "$GW_NAME" ]] || die "--name is required"
[[ -n "$WS_PORT" ]] || die "--ws-port is required"
[[ "$WS_PORT" =~ ^[0-9]+$ ]] || die "--ws-port must be numeric"

need_cmd openclaw
need_cmd node

BOTROOT="${ROOT}/gateways/${GW_NAME}"
CFGROOT="${BOTROOT}/.openclaw"
OPENCLAW_JSON="${CFGROOT}/openclaw.json"
ENV_FILE="${BOTROOT}/gateway.env"
WORKSPACE="${CFGROOT}/workspace"

# 포트 사용중 검사
if [[ $FORCE -eq 0 ]]; then
  if ss -ltn 2>/dev/null | grep -qE ":(?:${WS_PORT})\b"; then
    die "port ${WS_PORT} already in use. Choose another or use --force."
  fi
fi

# 디렉토리 생성 (sudo 자동 사용 안 함)
# 정책: 스크립트는 일반 사용자 권한으로만 실행.
# 권한이 없으면 사전 chown/chmod를 안내하고 종료.
PARENT_DIR="$(dirname "${BOTROOT}")"
mkdir -p "${PARENT_DIR}" || die "cannot create parent dir: ${PARENT_DIR}"

if [[ ! -w "${PARENT_DIR}" ]]; then
  die "no write permission on ${PARENT_DIR}.\nRun once as admin: sudo mkdir -p '${ROOT}' && sudo chown -R '$USER:$USER' '${ROOT}'"
fi

ensure_dirs \
  "${BOTROOT}/logs" "${BOTROOT}/run" "${BOTROOT}/config" "${BOTROOT}/state/cache" \
  "${CFGROOT}" "${WORKSPACE}"

# openclaw setup (인스턴스 전용 HOME/XDG 격리)
if [[ ! -s "$OPENCLAW_JSON" ]]; then
  echo "[*] Running: openclaw setup (HOME=${BOTROOT})"
  HOME="${BOTROOT}" \
  XDG_CONFIG_HOME="${BOTROOT}/config" \
  XDG_STATE_HOME="${BOTROOT}/state" \
  XDG_CACHE_HOME="${BOTROOT}/state/cache" \
    openclaw setup
fi

[[ -s "$OPENCLAW_JSON" ]] || die "openclaw.json not created at: $OPENCLAW_JSON"

# openclaw.json 보정 + (옵션) model + (옵션) auth.profiles 껍데기
ensure_gateway_config "$OPENCLAW_JSON" "$WORKSPACE" "$MODEL_PRIMARY"

# gateway.env 생성 (token 저장 금지, config path는 명시)
{
  printf 'OPENCLAW_GATEWAY_WS_PORT=%s\n' "$WS_PORT"
  printf 'OPENCLAW_GATEWAY_BIND=%s\n' "$BIND_MODE"
  printf 'OPENCLAW_WS_LOG=%s\n' "$WS_LOG"
  printf 'OPENCLAW_CONFIG_PATH=%s\n' "$OPENCLAW_JSON"
  printf 'OPENCLAW_WORKSPACE=%s\n' "$WORKSPACE"
} > "$ENV_FILE"
chmod 600 "$ENV_FILE"

# gateway.env 검증
if grep -nE $'[\r]' "$ENV_FILE" >/dev/null 2>&1; then
  die "gateway.env contains CRLF (^M). Recreate it with LF only."
fi
if grep -nE '^\s*export\s+' "$ENV_FILE" >/dev/null 2>&1; then
  die "gateway.env must not contain 'export'. Use KEY=VALUE only."
fi
grep -q '^OPENCLAW_GATEWAY_WS_PORT=' "$ENV_FILE" || die "gateway.env missing OPENCLAW_GATEWAY_WS_PORT"
grep -q '^OPENCLAW_CONFIG_PATH=' "$ENV_FILE" || die "gateway.env missing OPENCLAW_CONFIG_PATH"

echo
echo "✅ Gateway created/updated:"
echo "  Name      : $GW_NAME"
echo "  BOTROOT   : $BOTROOT"
echo "  WS Port   : $WS_PORT"
echo "  Env file  : $ENV_FILE"
echo "  Config    : $OPENCLAW_JSON"
echo "  Workspace : $WORKSPACE"
if [[ -n "$MODEL_PRIMARY" ]]; then
  echo "  Model     : $MODEL_PRIMARY"
  echo "  Auth      : auth.profiles[${MODEL_PRIMARY%%/*}:default] ensured (mode=oauth)"
fi
