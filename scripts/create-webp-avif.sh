#!/usr/bin/env bash
# convert_images.sh — Convert all JPEGs and PNGs in a folder to WebP and AVIF
# JPEGs are treated as photos (lossy). PNGs are auto-detected:
# few unique colors → lossless; many colors → lossy photo quality.
# Usage: ./convert_images.sh [input_dir] [photo_quality]
#   input_dir      - folder containing source images (default: current dir)
#   photo_quality  - lossy quality for photos 1–100 (default: 80)

set -euo pipefail

INPUT_DIR="${1:-.}"
OUTPUT_DIR="$INPUT_DIR"
QUALITY="${2:-80}"

# Color threshold: PNGs with fewer unique colors than this → lossless
COLOR_THRESHOLD=256

# Validate ImageMagick is available
if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
  echo "❌  ImageMagick not found. Install it first:"
  echo "    macOS:  brew install imagemagick"
  echo "    Ubuntu: sudo apt install imagemagick"
  exit 1
fi

# Use 'magick' (v7) or fall back to 'convert' (v6)
MAGICK=$(command -v magick 2>/dev/null || command -v convert)

# Check AVIF delegate support
if ! "$MAGICK" -list format 2>/dev/null | grep -qi "avif"; then
  echo "⚠️   AVIF support not detected in this ImageMagick build."
  echo "    macOS:  brew reinstall imagemagick"
  echo "    Ubuntu: sudo apt install imagemagick libheif-dev"
  echo "    Skipping AVIF output — WebP will still be generated."
  SKIP_AVIF=true
else
  SKIP_AVIF=false
fi

# Returns "lossless" or "lossy" for a given file
detect_mode() {
  local file="$1"
  local ext="${file##*.}"
  ext="${ext,,}"

  if [[ "$ext" == "jpg" || "$ext" == "jpeg" ]]; then
    echo "lossy"
    return
  fi

  local colors
  colors=$("$MAGICK" identify -format "%k" "$file" 2>/dev/null || echo "99999")
  if (( colors < COLOR_THRESHOLD )); then
    echo "lossless"
  else
    echo "lossy"
  fi
}

# Human-readable file size (bytes → KB or MB)
human_size() {
  local bytes="$1"
  if (( bytes >= 1048576 )); then
    awk "BEGIN { printf \"%.1f MB\", $bytes/1048576 }"
  else
    awk "BEGIN { printf \"%.1f KB\", $bytes/1024 }"
  fi
}

# Print size delta: original vs output, with % saving
size_delta() {
  local orig="$1"
  local out="$2"
  local orig_sz out_sz saving pct
  orig_sz=$(wc -c < "$orig")
  out_sz=$(wc -c < "$out")
  saving=$(( orig_sz - out_sz ))
  pct=$(awk "BEGIN { printf \"%.0f\", ($saving/$orig_sz)*100 }")
  if (( saving >= 0 )); then
    printf "%s → %s (-%s, -%s%%)" \
      "$(human_size "$orig_sz")" "$(human_size "$out_sz")" \
      "$(human_size "$saving")" "$pct"
  else
    # Output is larger (can happen with lossless on already-compressed sources)
    local increase=$(( -saving ))
    printf "%s → %s (+%s, +%s%%)" \
      "$(human_size "$orig_sz")" "$(human_size "$out_sz")" \
      "$(human_size "$increase")" "$(awk "BEGIN { printf \"%.0f\", ($increase/$orig_sz)*100 }")"
  fi
}

# Collect source files (flat, no subdirectories)
shopt -s nullglob nocaseglob
files=("$INPUT_DIR"/*.jpg "$INPUT_DIR"/*.jpeg "$INPUT_DIR"/*.png)
shopt -u nullglob nocaseglob

TOTAL=${#files[@]}
if [[ $TOTAL -eq 0 ]]; then
  echo "No JPEG or PNG files found in: $INPUT_DIR"
  exit 0
fi

echo "📂  Folder:  $INPUT_DIR"
echo "🎚   Photo quality: $QUALITY  |  Graphic threshold: <${COLOR_THRESHOLD} colors → lossless"
echo "🖼   Files:   $TOTAL"
echo "══════════════════════════════════════════════════════════════"

DONE=0
ERRORS=0

for src in "${files[@]}"; do
  filename=$(basename "$src")
  stem="${filename%.*}"
  mode=$(detect_mode "$src")

  webp_out="$OUTPUT_DIR/$stem.webp"
  avif_out="$OUTPUT_DIR/$stem.avif"

  if [[ "$mode" == "lossless" ]]; then
    webp_args=(-define webp:lossless=true)
    avif_args=(-quality 100)
    mode_label="lossless"
  else
    webp_args=(-quality "$QUALITY")
    avif_args=(-quality "$QUALITY")
    mode_label="lossy q${QUALITY}"
  fi

  echo ""
  printf "  📄 %s  [%s]\n" "$filename" "$mode_label"

  # WebP
  if "$MAGICK" "$src" "${webp_args[@]}" "$webp_out" 2>/dev/null; then
    printf "     ✅ webp  %s\n" "$(size_delta "$src" "$webp_out")"
  else
    printf "     ❌ webp  conversion failed\n"
    ERRORS=$(( ERRORS + 1 ))
  fi

  # AVIF
  if [[ "$SKIP_AVIF" == false ]]; then
    if "$MAGICK" "$src" "${avif_args[@]}" "$avif_out" 2>/dev/null; then
      printf "     ✅ avif  %s\n" "$(size_delta "$src" "$avif_out")"
    else
      printf "     ❌ avif  conversion failed\n"
      ERRORS=$(( ERRORS + 1 ))
    fi
  else
    printf "     ⏭  avif  skipped (no delegate)\n"
  fi

  DONE=$(( DONE + 1 ))
done

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "✔  Done: $DONE files  |  Errors: $ERRORS"
