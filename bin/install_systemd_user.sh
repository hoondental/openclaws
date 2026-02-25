#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "${SCRIPT_DIR}/../systemd" && pwd)"
DST="${HOME}/.config/systemd/user"

mkdir -p "$DST"

install -m 644 "${SRC}/openclaw-gateway@.service" "$DST/openclaw-gateway@.service"
install -m 644 "${SRC}/openclaw-node@.service" "$DST/openclaw-node@.service"

systemctl --user daemon-reload
echo "✅ Installed user units to: $DST"
echo "   - openclaw-gateway@.service"
echo "   - openclaw-node@.service"
