#!/usr/bin/env bash
set -euo pipefail

MIN_NODE_MAJOR=20
CHECK_OPENCLAW=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-openclaw) CHECK_OPENCLAW=1; shift;;
    -h|--help)
      echo "Usage: $0 [--check-openclaw]"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

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

if [[ $CHECK_OPENCLAW -eq 1 ]]; then
  if command -v openclaw >/dev/null 2>&1; then
    ok "openclaw: $(openclaw --version 2>/dev/null || echo 'installed')"
  else
    fail "openclaw not found (install first or run install.sh --install-openclaw-if-missing)"
  fi
fi

echo "✅ Environment looks good"
