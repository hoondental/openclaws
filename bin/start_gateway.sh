#!/usr/bin/env bash
set -euo pipefail

die(){ echo "ERROR: $*" >&2; exit 1; }

ROOT="${OPENCLAWS_HOME:-$HOME/openclaws}"
NAME=""
FOREGROUND=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2;;
    --name) NAME="${2:-}"; shift 2;;
    --foreground) FOREGROUND=1; shift;;
    -h|--help) sed -n '1,160p' "$0"; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

[[ -n "$NAME" ]] || die "--name is required"

if [[ $FOREGROUND -eq 1 ]]; then
  exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/run_gateway_instance.sh" "$NAME"
else
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  systemctl --user start "openclaw-gateway@${NAME}.service"
  systemctl --user status "openclaw-gateway@${NAME}.service" --no-pager -l
fi
