#!/usr/bin/env bash
# Installs Vinyasa for the current user (no root needed).
#
#   ./install.sh                 # from an unpacked release tarball
#   scripts/install-linux.sh     # from a source checkout, after `flutter build linux --release`
#   ./install.sh --uninstall     # removes the app; your data stays
#
# The app goes to ~/.local/lib/vinyasa, a launcher to ~/.local/bin/vinyasa and a
# menu entry to ~/.local/share/applications. Your encrypted data lives in
# ~/.local/share/dev.brahma.vinyasa and its key in the desktop keyring; neither
# is touched by installing, upgrading or uninstalling.
set -euo pipefail

app_id=dev.brahma.vinyasa
dest="$HOME/.local/lib/vinyasa"
bin="$HOME/.local/bin/vinyasa"
desktop="$HOME/.local/share/applications/$app_id.desktop"
icon="$HOME/.local/share/icons/hicolor/512x512/apps/$app_id.png"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ${1:-} == --uninstall ]]; then
  rm -rf "$dest"
  rm -f "$bin" "$desktop" "$icon"
  command -v update-desktop-database >/dev/null && update-desktop-database -q "$(dirname "$desktop")" || true
  echo "Vinyasa removed. Your data is still in ~/.local/share/$app_id."
  exit 0
fi

# A release tarball has the app next to this script; a checkout has it in build/.
if [[ -x $here/vinyasa ]]; then
  bundle="$here"
  png="$here/vinyasa.png"
else
  root="$(cd "$here/.." && pwd)"
  bundle="$root/build/linux/x64/release/bundle"
  png="$root/branding/vinyasa-512.png"
  if [[ ! -x $bundle/vinyasa ]]; then
    echo "No build found. Run: flutter build linux --release" >&2
    exit 1
  fi
fi

# The database key is kept in the desktop keyring through libsecret.
# grep reads all input (no -q): under pipefail an early exit would fail the pipe.
if ! ldconfig -p 2>/dev/null | grep libsecret-1.so.0 >/dev/null; then
  echo "Warning: libsecret is not installed. Install it (e.g. libsecret / libsecret-1-0) or Vinyasa cannot store its key." >&2
fi
if command -v busctl >/dev/null && ! busctl --user list 2>/dev/null | grep org.freedesktop.secrets >/dev/null; then
  echo "Note: no keyring service is running right now (GNOME Keyring or KWallet). Vinyasa needs one when it starts." >&2
fi

# Copy beside the old install, then swap, so a failed copy leaves it working.
mkdir -p "$(dirname "$dest")"
staging="$(mktemp -d "$dest.new.XXXXXX")"
chmod 755 "$staging"
trap 'rm -rf "$staging"' EXIT
cp -a "$bundle/vinyasa" "$bundle/lib" "$bundle/data" "$staging/"
rm -rf "$dest.old"
[[ -e $dest ]] && mv "$dest" "$dest.old"
mv "$staging" "$dest"
rm -rf "$dest.old"
trap - EXIT

mkdir -p "$(dirname "$bin")" "$(dirname "$desktop")" "$(dirname "$icon")"
ln -sf "$dest/vinyasa" "$bin"
[[ -f $png ]] && cp "$png" "$icon"
cat >"$desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Vinyasa
GenericName=Personal finance
Comment=Accounts, spending, investments and reports in one private ledger
Exec=$dest/vinyasa
Icon=$app_id
Terminal=false
Categories=Office;Finance;
Keywords=money;budget;accounts;ledger;investments;
StartupWMClass=$app_id
DESKTOP
command -v update-desktop-database >/dev/null && update-desktop-database -q "$(dirname "$desktop")" || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "Vinyasa installed. Start it from your app menu or run: vinyasa"
