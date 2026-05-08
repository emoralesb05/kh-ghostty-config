#!/bin/bash
set -euo pipefail

# kh-ghostty-config installer — themes, shaders, kh-variant + kh-shader CLIs
# Modes:
#   Local:  bash install.sh              (run from cloned repo)
#   Remote: bash <(curl -fsSL <url>)     (downloads sources, then symlinks)

REPO="emoralesb05/kh-ghostty-config"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

GHOSTTY_DIR="$HOME/.config/ghostty"
THEMES_DST="$GHOSTTY_DIR/themes"
SHADERS_DST="$GHOSTTY_DIR/shaders"
ASSETS_DST="$GHOSTTY_DIR/assets"
BIN_DIR="$HOME/.local/bin"
CACHE_DIR="$HOME/.local/share/kh-ghostty-config"
TS="$(date +%Y%m%d-%H%M%S)"

THEMES=(kh-gold kh-silver)
SHADERS=(dive-to-heart destiny-islands twilight-town)
ASSETS=(dive-to-heart-bg.png twilight-town-bg.png)

# --- Detect local vs remote mode ---
LOCAL_MODE=false
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -d "$SCRIPT_DIR/themes" ] && [ -d "$SCRIPT_DIR/shaders" ]; then
    LOCAL_MODE=true
  fi
fi

# Source root: where the canonical files live after this script runs
if [ "$LOCAL_MODE" = true ]; then
  SRC_ROOT="$SCRIPT_DIR"
else
  SRC_ROOT="$CACHE_DIR"
fi

echo ""
echo "  ============================================="
echo "  kh-ghostty-config — Kingdom Hearts × Ghostty"
echo "  ============================================="
echo ""

# Detect update vs fresh
UPDATING=false
if [ -L "$THEMES_DST/kh-gold" ] || [ -L "$THEMES_DST/kh-silver" ] \
   || [ -L "$BIN_DIR/kh-variant" ] || [ -L "$BIN_DIR/kh-shader" ]; then
  UPDATING=true
  echo "  Existing install found. Updating..."
else
  echo "  May your heart be your guiding key."
fi
echo ""

# Ensure target dirs
mkdir -p "$THEMES_DST" "$SHADERS_DST" "$ASSETS_DST" "$BIN_DIR"

# --- Helpers ---

# Move an existing real file/dir/link out of the way (with timestamped backup)
backup_if_exists() {
  local dst="$1"
  if [ -L "$dst" ]; then
    # If it's already a symlink we own (points into SRC_ROOT or CACHE_DIR), just remove it
    local target
    target="$(readlink "$dst" || true)"
    case "$target" in
      "$SRC_ROOT"/*|"$CACHE_DIR"/*) rm -f "$dst" ;;
      *)
        mv "$dst" "$dst.bak.$TS"
        echo "  Backed up existing symlink: $dst → $dst.bak.$TS"
        ;;
    esac
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak.$TS"
    echo "  Backed up existing file: $dst → $dst.bak.$TS"
  fi
}

# Download a file from the GitHub raw URL into the cache dir
fetch_to_cache() {
  local rel="$1"
  local dst="$CACHE_DIR/$rel"
  mkdir -p "$(dirname "$dst")"
  echo "  Downloading $rel..."
  curl -fsSL "$RAW_URL/$rel" -o "$dst"
}

# --- Remote: pre-fetch sources into cache ---
if [ "$LOCAL_MODE" = false ]; then
  echo "  Installing from GitHub (remote mode)..."
  echo "  Source cache: $CACHE_DIR"
  mkdir -p "$CACHE_DIR/themes" "$CACHE_DIR/shaders" "$CACHE_DIR/assets" "$CACHE_DIR/bin"
  for t in "${THEMES[@]}"; do
    fetch_to_cache "themes/$t"
  done
  for s in "${SHADERS[@]}"; do
    fetch_to_cache "shaders/$s.glsl"
  done
  for a in "${ASSETS[@]}"; do
    fetch_to_cache "assets/$a"
  done
  fetch_to_cache "bin/kh-variant"
  fetch_to_cache "bin/kh-shader"
  fetch_to_cache "VERSION"
  fetch_to_cache "uninstall.sh"
  chmod +x "$CACHE_DIR/bin/kh-variant" "$CACHE_DIR/bin/kh-shader" "$CACHE_DIR/uninstall.sh"
  echo ""
else
  echo "  Installing from local source: $SCRIPT_DIR"
  echo ""
fi

# --- Themes ---
echo "  Linking themes..."
for t in "${THEMES[@]}"; do
  src="$SRC_ROOT/themes/$t"
  dst="$THEMES_DST/$t"
  if [ ! -e "$src" ]; then
    echo "  WARN: source missing: $src"
    continue
  fi
  backup_if_exists "$dst"
  ln -sf "$src" "$dst"
  echo "    $dst → $src"
done

# --- Shaders ---
echo "  Linking shaders..."
for s in "${SHADERS[@]}"; do
  src="$SRC_ROOT/shaders/$s.glsl"
  dst="$SHADERS_DST/$s.glsl"
  if [ ! -e "$src" ]; then
    echo "  WARN: source missing: $src"
    continue
  fi
  backup_if_exists "$dst"
  ln -sf "$src" "$dst"
  echo "    $dst → $src"
done

# --- Assets ---
echo "  Linking assets..."
for a in "${ASSETS[@]}"; do
  src="$SRC_ROOT/assets/$a"
  dst="$ASSETS_DST/$a"
  if [ ! -e "$src" ]; then
    echo "  WARN: source missing: $src"
    continue
  fi
  backup_if_exists "$dst"
  ln -sf "$src" "$dst"
  echo "    $dst → $src"
done

# --- bin/kh-variant + bin/kh-shader ---
echo "  Installing CLIs..."
for cli in kh-variant kh-shader; do
  src="$SRC_ROOT/bin/$cli"
  dst="$BIN_DIR/$cli"
  if [ -e "$src" ]; then
    backup_if_exists "$dst"
    ln -sf "$src" "$dst"
    chmod +x "$src"
    echo "    $dst → $src"
  fi
done

echo ""

# --- PATH guidance ---
case ":${PATH:-}:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo "  Note: $BIN_DIR is not on your PATH."
    echo "        Add to ~/.config/fish/config.fish:"
    echo "          fish_add_path $BIN_DIR"
    echo "        Or to ~/.zshrc:"
    echo "          export PATH=\"$BIN_DIR:\$PATH\""
    echo ""
    ;;
esac

echo "  ============================================="
echo "  Setup complete!"
echo "  ============================================="
echo ""
echo "  Add to ~/.config/ghostty/config (if not already):"
echo "    theme = kh-gold"
echo "    custom-shader = ~/.config/ghostty/shaders/dive-to-heart.glsl"
echo "    background-image = ~/.config/ghostty/assets/dive-to-heart-bg.png"
echo "    background-image-opacity = 0.22"
echo "    background-image-position = center"
echo "    background-image-fit = cover"
echo "    background-opacity = 0.82"
echo "    background-blur = 30"
echo ""
echo "  Reload Ghostty:   cmd+shift+,"
echo "  Switch variants:  kh-variant toggle"
echo "  Switch shaders:   kh-shader toggle    (or: kh-shader auto)"
echo "  Check active:     kh-variant status / kh-shader status"
echo ""
echo "  May your heart be your guiding key."
echo ""
