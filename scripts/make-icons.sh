#!/usr/bin/env bash
# Regenerates every platform icon from branding/vinyasa.svg.
# Needs rsvg-convert (librsvg) and ImageMagick.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
svg="$root/branding/vinyasa.svg"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

png() { rsvg-convert -w "$1" -h "$1" "$svg" -o "$2"; }

# Android launcher icons.
for pair in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  png "${pair#*:}" "$root/android/app/src/main/res/mipmap-${pair%%:*}/ic_launcher.png"
done

# Windows: one .ico with the sizes Explorer and the taskbar ask for.
frames=()
for s in 16 24 32 48 64 128 256; do
  png "$s" "$tmp/$s.png"
  frames+=("$tmp/$s.png")
done
magick "${frames[@]}" "$root/windows/runner/resources/app_icon.ico"

# Linux: installed by scripts/install-linux.sh and bundled in the tarball.
png 512 "$root/branding/vinyasa-512.png"
echo "Icons written."
