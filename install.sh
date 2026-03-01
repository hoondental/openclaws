#!/usr/bin/env bash
set -euo pipefail

# install.sh
# Deploy openclaws scripts from this repo checkout to a target install dir.
#
# Defaults:
#   --install-dir /opt/openclaws
#
# Optional:
#   --install-service-template   install user systemd templates (~/.config/systemd/user)
#   --gateway-name <name> --gateway-port <port> [--gateway-bind <mode>] [--gateway-model <provider/model>]
#   --node-name <name>          (requires --gateway-name)
#   --start                     start created services
#   --install-openclaw-if-missing  auto-install openclaw CLI when missing
#   --openclaw-version <ver>    install specific openclaw version (default: 2026.2.26)
#
# Example:
#   ./install.sh --install-service-template \
#     --gateway-name gw_chatgpt --gateway-port 21100 --node-name gw_chatgpt-1 --start

INSTALL_DIR="/opt/openclaws"
INSTALL_SERVICE_TEMPLATE=0
START_AFTER=0
INSTALL_OPENCLAW_IF_MISSING=0
OPENCLAW_VERSION="2026.2.26"

GW_NAME=""
GW_PORT=""
GW_BIND="loopback"
GW_MODEL=""
NODE_NAME=""

usage() { sed -n '1,220p' "$0"; }

die(){ echo "ERROR: $*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir) INSTALL_DIR="${2:-}"; shift 2;;
    --install-service-template) INSTALL_SERVICE_TEMPLATE=1; shift;;
    --gateway-name) GW_NAME="${2:-}"; shift 2;;
    --gateway-port|--ws-port) GW_PORT="${2:-}"; shift 2;;
    --gateway-bind) GW_BIND="${2:-}"; shift 2;;
    --gateway-model) GW_MODEL="${2:-}"; shift 2;;
    --node-name) NODE_NAME="${2:-}"; shift 2;;
    --start) START_AFTER=1; shift;;
    --install-openclaw-if-missing) INSTALL_OPENCLAW_IF_MISSING=1; shift;;
    --openclaw-version) OPENCLAW_VERSION="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

need rsync

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$SCRIPT_DIR"

install_openclaw_cli(){
  need npm
  local spec="openclaw"
  if [[ -n "$OPENCLAW_VERSION" ]]; then
    spec="openclaw@${OPENCLAW_VERSION}"
  fi

  add_npm_global_bin_to_path(){
    local gprefix gbin
    gprefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$gprefix" && "$gprefix" != "undefined" && "$gprefix" != "null" ]]; then
      gbin="$gprefix/bin"
      if [[ -d "$gbin" ]]; then
        case ":$PATH:" in
          *":$gbin:"*) ;;
          *) export PATH="$gbin:$PATH" ;;
        esac
      fi
    fi

    # Common fallback locations
    for d in "$HOME/.local/bin" "$HOME/.npm-global/bin" "/usr/local/bin"; do
      if [[ -d "$d" ]]; then
        case ":$PATH:" in
          *":$d:"*) ;;
          *) export PATH="$d:$PATH" ;;
        esac
      fi
    done

    hash -r 2>/dev/null || true
  }

  echo "[*] Installing ${spec} ..."
  # Prefer global install first; fallback to user prefix if permission denied.
  if npm install -g "$spec"; then
    add_npm_global_bin_to_path
    return 0
  fi

  echo "[!] Global npm install failed. Trying user-level npm prefix..."
  npm config set prefix "$HOME/.local" >/dev/null 2>&1 || true
  if npm install -g "$spec"; then
    add_npm_global_bin_to_path
    export PATH="$HOME/.local/bin:$PATH"
    return 0
  fi

  # If pinned version is missing on npm, fallback to latest.
  if [[ -n "$OPENCLAW_VERSION" ]]; then
    echo "[!] Requested openclaw@${OPENCLAW_VERSION} not installable. Falling back to latest 'openclaw'."
    if npm install -g openclaw; then
      add_npm_global_bin_to_path
      export PATH="$HOME/.local/bin:$PATH"
      return 0
    fi
  fi

  die "Failed to install openclaw CLI via npm"
}

ensure_openclaw_cli(){
  if command -v openclaw >/dev/null 2>&1; then
    return 0
  fi

  if [[ $INSTALL_OPENCLAW_IF_MISSING -eq 1 ]]; then
    install_openclaw_cli
    if ! command -v openclaw >/dev/null 2>&1; then
      echo "[!] npm prefix: $(npm config get prefix 2>/dev/null || echo unknown)"
      echo "[!] PATH: $PATH"
      die "openclaw install attempted but command still not found (PATH issue likely)"
    fi
    return 0
  fi

  if [[ -t 0 ]]; then
    echo "[!] 'openclaw' command not found."
    read -r -p "Install openclaw CLI now? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      install_openclaw_cli
      command -v openclaw >/dev/null 2>&1 || die "openclaw install attempted but command still not found"
      return 0
    fi
  fi

  die "'openclaw' is required. Install it first (or rerun with --install-openclaw-if-missing)."
}

ensure_openclaw_cli

mkdir -p "$INSTALL_DIR"

# Deploy directories
rsync -a --delete "$SRC_ROOT/bin/" "$INSTALL_DIR/bin/"
rsync -a --delete "$SRC_ROOT/systemd/" "$INSTALL_DIR/systemd/"
rsync -a "$SRC_ROOT/docs/" "$INSTALL_DIR/docs/" 2>/dev/null || true
cp -f "$SRC_ROOT/README.md" "$INSTALL_DIR/README.md" 2>/dev/null || true

chmod +x "$INSTALL_DIR"/bin/*.sh

# Patch systemd ExecStart to actual install dir
sed -i "s|^ExecStart=.*run_gateway_instance.sh .*|ExecStart=${INSTALL_DIR}/bin/run_gateway_instance.sh %i|" "$INSTALL_DIR/systemd/openclaw-gateway@.service"
sed -i "s|^ExecStart=.*run_node_instance.sh .*|ExecStart=${INSTALL_DIR}/bin/run_node_instance.sh %i|" "$INSTALL_DIR/systemd/openclaw-node@.service"

# Ensure scripts source local ocw-lib
# (already relative in repo; no-op if unchanged)

echo "✅ Installed scripts to: $INSTALL_DIR"
echo "   - $INSTALL_DIR/bin"
echo "   - $INSTALL_DIR/systemd"

# Install user services (template copy)
if [[ $INSTALL_SERVICE_TEMPLATE -eq 1 ]]; then
  "$INSTALL_DIR/bin/install_systemd_user.sh"
fi

# Optional bootstrap gateway/node
if [[ -n "$GW_NAME" || -n "$GW_PORT" ]]; then
  [[ -n "$GW_NAME" ]] || die "--gateway-name required when using gateway bootstrap options"
  [[ -n "$GW_PORT" ]] || die "--gateway-port required when using gateway bootstrap options"

  cmd=("$INSTALL_DIR/bin/create_gateway.sh" --name "$GW_NAME" --ws-port "$GW_PORT" --bind "$GW_BIND")
  if [[ -n "$GW_MODEL" ]]; then cmd+=(--model "$GW_MODEL"); fi
  "${cmd[@]}"

  if [[ -n "$NODE_NAME" ]]; then
    "$INSTALL_DIR/bin/create_node.sh" --name "$NODE_NAME" --gateway "$GW_NAME"
  fi

  if [[ $START_AFTER -eq 1 ]]; then
    "$INSTALL_DIR/bin/start_gateway.sh" --name "$GW_NAME"
    if [[ -n "$NODE_NAME" ]]; then
      "$INSTALL_DIR/bin/start_node.sh" --name "$NODE_NAME"
    fi
  fi
fi

echo "Done."
