#!/usr/bin/env bash
set -euo pipefail

MIN_NODE_MAJOR=20

fail(){ echo "[FAIL] $*"; exit 1; }
ok(){ echo "[OK] $*"; }

command -v git >/dev/null 2>&1 || fail "git not found"
command -v rsync >/dev/null 2>&1 || fail "rsync not found"
command -v node >/dev/null 2>&1 || fail "node not found"
command -v npm >/dev/null 2>&1 || fail "npm not found"

ok "git: $(git --version)"
ok "npm: $(npm -v)"

NODE_VER="$(node -v | sed 's/^v//')"
NODE_MAJOR="${NODE_VER%%.*}"
if [[ "$NODE_MAJOR" -lt "$MIN_NODE_MAJOR" ]]; then
  fail "node version too old: v$NODE_VER (need >= ${MIN_NODE_MAJOR})"
fi
ok "node: v$NODE_VER"

echo "✅ Environment looks good"
