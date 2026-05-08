#!/bin/bash
set -euo pipefail

# kh-ghostty-config uninstaller — removes symlinks, restores backups, removes CLIs

GHOSTTY_DIR="$HOME/.config/ghostty"
THEMES_DST="$GHOSTTY_DIR/themes"
SHADERS_DST="$GHOSTTY_DIR/shaders"
ASSETS_DST="$GHOSTTY_DIR/assets"
BIN_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.local/share/kh-ghostty-config"

THEMES=(kh-gold kh-silver)
SHADERS=(dive-to-heart destiny-islands twilight-town)
ASSETS=(dive-to-heart-bg.png destiny-islands-bg.png twilight-town-bg.png)

echo ""
echo "  === kh-ghostty-config uninstaller ==="
echo ""

# Remove a managed symlink and restore the most recent matching backup, if any
remove_and_restore() {
  local dst="$1"
  if [ -L "$dst" ] || [ -e "$dst" ]; then
    if [ -L "$dst" ]; then
      rm -f "$dst"
      echo "  Removed symlink: $dst"
    fi
    # Find the newest .bak.* sibling
    local backup
    backup="$(ls -1t "$dst".bak.* 2>/dev/null | head -n1 || true)"
    if [ -n "$backup" ] && [ -e "$backup" ]; then
      mv "$backup" "$dst"
      echo "  Restored backup: $dst (from $(basename "$backup"))"
    fi
  fi
}

# Themes & shaders
for t in "${THEMES[@]}"; do
  remove_and_restore "$THEMES_DST/$t"
done
for s in "${SHADERS[@]}"; do
  remove_and_restore "$SHADERS_DST/$s.glsl"
done
for a in "${ASSETS[@]}"; do
  remove_and_restore "$ASSETS_DST/$a"
done

# CLIs
remove_and_restore "$BIN_DIR/kh-variant"
remove_and_restore "$BIN_DIR/kh-shader"

# Erase the fish universal var (if fish is available)
if command -v fish &>/dev/null; then
  fish -c 'set -e -U KH_VARIANT' 2>/dev/null || true
  echo "  Cleared fish universal var KH_VARIANT"
fi

# Cache (only present in remote-install setups)
if [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR"
  echo "  Removed source cache: $CACHE_DIR"
fi

echo ""
echo "  === Uninstall complete ==="
echo "  May your heart be your guiding key."
echo ""
