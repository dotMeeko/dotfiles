#!/usr/bin/env bash
# Install Homebrew (if missing), then packages from ./Brewfile (repo root).
# Run from repo root: ./scripts/macos/bootstrap.sh
#
# First-time macOS may prompt for: Xcode CLT, sudo (Homebrew), or GUI dialogs.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  local brew_exe
  for brew_exe in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_exe" ]]; then
      eval "$("$brew_exe" shellenv)"
      return 0
    fi
  done

  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script only supports macOS." >&2
    exit 1
  fi

  echo "==> Homebrew not found; running official installer (may ask for password / CLT)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew installed but brew is not on PATH. Open a new terminal or add brew to PATH, then re-run." >&2
    exit 1
  fi
}

ensure_homebrew

if [[ ! -f "$ROOT/Brewfile" ]]; then
  echo "Missing $ROOT/Brewfile" >&2
  exit 1
fi

echo "==> brew bundle install..."
brew bundle install

echo "Done. dotter: $(command -v dotter)"
echo "Done. nvim:  $(command -v nvim)"
