#!/usr/bin/env bash
set -euo pipefail
NAME="${1:-}"
[[ -n "$NAME" ]] || { echo "Usage: $0 <node_name>" >&2; exit 2; }
systemctl --user stop "openclaw-node@${NAME}.service"
