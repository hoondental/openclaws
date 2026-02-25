#!/usr/bin/env bash
set -euo pipefail
ROOT="${OPENCLAWS_HOME:-$HOME/openclaws}"
echo "[Gateways]"
ls -1 "${ROOT}/gateways" 2>/dev/null || true
echo
echo "[Nodes]"
ls -1 "${ROOT}/nodes" 2>/dev/null | grep -v '\.env$' || true
