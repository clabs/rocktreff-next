#!/usr/bin/env bash
# build_image_set.sh — Generate a responsive image set from a source image.
# Produces WebP and AVIF at multiple widths, named with @width suffixes.
# Usage: ./build_image_set.sh <source_image> [quality] [widths]
#   source_image  - path to the original image (any format ImageMagick supports)
#   quality       - lossy quality 1–100 (default: 80); lossless auto-applied to graphics
#   widths        - comma-separated pixel widths (default: 320,640,960,1280,1920)
#
# Output naming: <stem>@<width>w.webp / .avif — written next to the source file
# Example: hero.jpg → hero@320w.webp, hero@320w.avif, hero@640w.webp ...

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
SRC="${1:-}"
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Usage: $0 <source_image> [quality] [widths]"
  echo "  Example: $0 hero.jpg 80 320,640,1280"
  exit 1
fi

SRC_DIR=$(dirname "$SRC")
OUTPUT_DIR="$SRC_DIR"
QUALITY="${2:-80}"
WIDTHS_RAW="${3:-320,640,960,1280,1920}"

# Parse widths into array
IFS=',' read -ra WIDTHS <<< "$WIDTHS_RAW"

# ── ImageMagick ───────────────────────────────────────────────────────────────
if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
  echo "❌  ImageMagick not found."
  echo "    macOS:  brew install imagemagick"
  echo "    Ubuntu: sudo apt install imagemagick"
  exit 1
fi
MAGICK=$(command -v magick 2>/dev/null || command -v convert)

if ! "$MAGICK" -list format 2>/dev/null | grep -qi "avif"; then
  echo "⚠️   AVIF support not detected — skipping AVIF output."
  echo "    macOS:  brew reinstall imagemagick"
  echo "    Ubuntu: sudo apt install imagemagick libheif-dev"
  SKIP_AVIF=true
else
  SKIP_AVIF=false
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
human_size() {
  local bytes="$1"
  if (( bytes >= 1048576 )); then
    awk "BEGIN { printf \"%.1f MB\", $bytes/1048576 }"
  else
    awk "BEGIN { printf \"%.1f KB\", $bytes/1024 }"
  fi
}

size_info() {
  local out="$1"
  local sz
  sz=$(wc -c < "$out")
  human_size "$sz"
}

# ── Detect lossless vs lossy (same heuristic as convert_images.sh) ────────────
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
  if (( colors < 256 )); then
    echo "lossless"
  else
    echo "lossy"
  fi
}

# ── Source image info ─────────────────────────────────────────────────────────
filename=$(basename "$SRC")
stem="${filename%.*}"
src_width=$("$MAGICK" identify -format "%w" "$SRC" 2>/dev/null)
src_height=$("$MAGICK" identify -format "%h" "$SRC" 2>/dev/null)
src_size=$(wc -c < "$SRC")
mode=$(detect_mode "$SRC")

if [[ "$mode" == "lossless" ]]; then
  webp_args=(-define webp:lossless=true)
  avif_args=(-quality 100)
  jpeg_args=(-quality 90)
  mode_label="lossless"
else
  webp_args=(-quality "$QUALITY")
  avif_args=(-quality "$QUALITY")
  jpeg_args=(-quality "$QUALITY")
  mode_label="lossy q${QUALITY}"
fi

# Always include native resolution
if ! printf '%s\n' "${WIDTHS[@]}" | grep -qx "$src_width"; then
  WIDTHS+=("$src_width")
fi
# Sort widths numerically
IFS=$'\n' WIDTHS=($(printf '%s\n' "${WIDTHS[@]}" | sort -n)); unset IFS

echo "📄  Source:   $filename  (${src_width}×${src_height}, $(human_size "$src_size"))"
echo "📁  Output:   $OUTPUT_DIR"
echo "🎚   Mode:     $mode_label"
echo "📐  Widths:   ${WIDTHS[*]}"
echo "══════════════════════════════════════════════════════════════"

DONE=0
SKIPPED=0
ERRORS=0

for w in "${WIDTHS[@]}"; do
  # Skip widths larger than the source — never upscale
  if (( w > src_width )); then
    printf "\n  ⏭  %s@%sw  (skipped — source is only %spx wide)\n" "$stem" "$w" "$src_width"
    SKIPPED=$(( SKIPPED + 1 ))
    continue
  fi

  webp_out="$OUTPUT_DIR/${stem}@${w}w.webp"
  avif_out="$OUTPUT_DIR/${stem}@${w}w.avif"
  jpeg_out="$OUTPUT_DIR/${stem}@${w}w.jpg"

  # Resize flag: scale to width, preserve aspect ratio
  resize_arg="${w}x>"

  printf "\n  📐 %s@%sw\n" "$stem" "$w"

  # JPEG
  if "$MAGICK" "$SRC" -resize "$resize_arg" "${jpeg_args[@]}" "$jpeg_out" 2>/dev/null; then
    printf "     ✅ jpg   %s\n" "$(size_info "$jpeg_out")"
  else
    printf "     ❌ jpg   conversion failed\n"
    ERRORS=$(( ERRORS + 1 ))
  fi

  # WebP
  if "$MAGICK" "$SRC" -resize "$resize_arg" "${webp_args[@]}" "$webp_out" 2>/dev/null; then
    printf "     ✅ webp  %s\n" "$(size_info "$webp_out")"
  else
    printf "     ❌ webp  conversion failed\n"
    ERRORS=$(( ERRORS + 1 ))
  fi

  # AVIF
  if [[ "$SKIP_AVIF" == false ]]; then
    if "$MAGICK" "$SRC" -resize "$resize_arg" "${avif_args[@]}" "$avif_out" 2>/dev/null; then
      printf "     ✅ avif  %s\n" "$(size_info "$avif_out")"
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
echo "✔  Generated: $DONE sizes  |  Skipped: $SKIPPED  |  Errors: $ERRORS"

# Print a ready-to-use <picture> srcset snippet
echo ""
echo "── <picture> snippet ─────────────────────────────────────────"
echo "<picture>"

# AVIF srcset
if [[ "$SKIP_AVIF" == false ]]; then
  printf "  <source type=\"image/avif\" srcset=\""
  first=true
  for w in "${WIDTHS[@]}"; do
    (( w > src_width )) && continue
    if [[ "$first" == true ]]; then
      printf "%s@%sw.avif %sw" "$stem" "$w" "$w"
      first=false
    else
      printf ",\n                              %s@%sw.avif %sw" "$stem" "$w" "$w"
    fi
  done
  printf "\">\n"
fi

# WebP srcset
printf "  <source type=\"image/webp\" srcset=\""
first=true
for w in "${WIDTHS[@]}"; do
  (( w > src_width )) && continue
  if [[ "$first" == true ]]; then
    printf "%s@%sw.webp %sw" "$stem" "$w" "$w"
    first=false
  else
    printf ",\n                              %s@%sw.webp %sw" "$stem" "$w" "$w"
  fi
done
printf "\">\n"

# JPEG srcset for <img> fallback
printf "  <img src=\"%s@%sw.jpg\"\n       srcset=\"" "$stem" "${WIDTHS[0]}"
first=true
for w in "${WIDTHS[@]}"; do
  (( w > src_width )) && continue
  if [[ "$first" == true ]]; then
    printf "%s@%sw.jpg %sw" "$stem" "$w" "$w"
    first=false
  else
    printf ",\n               %s@%sw.jpg %sw" "$stem" "$w" "$w"
  fi
done
printf "\" alt=\"\">\n"
echo "</picture>"
