#!/usr/bin/env bash
# Sensible macOS defaults (small, reversible). Inspired by mathiasbynens/dotfiles `.macos`.
# Run manually after you read it: ./scripts/macos/defaults.sh
#
# Some changes need a Finder restart; a few may need logout/login on newer macOS.
# Undo: use `defaults delete <domain> <key>` or flip the bool.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

echo "==> Applying macOS defaults..."

# Avoid .DS_Store on external volumes and network shares
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Restart Finder so Finder-related preferences apply
killall Finder 2>/dev/null || true

echo "==> Done."
