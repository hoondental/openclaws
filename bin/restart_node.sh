#!/usr/bin/env bash
set -euo pipefail
NAME="${1:-}"
[[ -n "$NAME" ]] || { echo "Usage: $0 <node_name>" >&2; exit 2; }
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user restart "openclaw-node@${NAME}.service"
systemctl --user status "openclaw-node@${NAME}.service" --no-pager -l
