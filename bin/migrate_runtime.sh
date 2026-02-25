#!/usr/bin/env bash
set -euo pipefail

OLD_ROOT="/opt/openclaws"
NEW_ROOT="${OPENCLAWS_HOME:-$HOME/openclaws}"

mkdir -p "$NEW_ROOT/gateways" "$NEW_ROOT/nodes"

move_dir(){
  local src="$1" dst="$2"
  if [[ -L "$src" ]]; then
    echo "[skip] $src already symlink"
    return
  fi
  if [[ -d "$src" ]]; then
    if [[ -z "$(ls -A "$src" 2>/dev/null)" ]]; then
      echo "[skip] $src empty"
      return
    fi
    rsync -a "$src/" "$dst/"
    mv "$src" "${src}.bak.$(date +%Y%m%d%H%M%S)"
    ln -s "$dst" "$src"
    echo "[ok] migrated $src -> $dst (backup kept)"
  else
    echo "[skip] $src not found"
  fi
}

move_dir "$OLD_ROOT/gateways" "$NEW_ROOT/gateways"
move_dir "$OLD_ROOT/nodes" "$NEW_ROOT/nodes"

echo "Done. Runtime root: $NEW_ROOT"
