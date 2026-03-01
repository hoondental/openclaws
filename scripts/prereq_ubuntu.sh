#!/usr/bin/env bash
set -euo pipefail

# Prerequisite installer for Ubuntu/Debian-like systems
# - git, curl, rsync, build tools
# - nvm
# - Node.js 22 (default)
# - npm via node
#
# Usage:
#   ./scripts/prereq_ubuntu.sh
#   ./scripts/prereq_ubuntu.sh --node 22

NODE_MAJOR="22"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --node) NODE_MAJOR="${2:-22}"; shift 2;;
    -h|--help)
      sed -n '1,200p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is required" >&2
  exit 1
fi

echo "[*] Installing apt prerequisites..."
sudo apt update
sudo apt install -y \
  ca-certificates \
  curl \
  git \
  rsync \
  build-essential \
  jq

export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo "[*] Installing nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# shellcheck disable=SC1090
source "$NVM_DIR/nvm.sh"

echo "[*] Installing Node.js ${NODE_MAJOR} via nvm..."
nvm install "$NODE_MAJOR"
nvm use "$NODE_MAJOR"
nvm alias default "$NODE_MAJOR"

echo "[*] Final versions"
echo "node: $(node -v)"
echo "npm : $(npm -v)"
echo "git : $(git --version)"

echo "✅ Prerequisites ready"
