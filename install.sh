#!/usr/bin/env bash
# One-command NixOS install entry point. Run from the repo root on the live ISO:
#   ./install.sh
# It elevates with sudo and runs the real installer. Asks only for password + disk.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec sudo bash "$here/nix/bootstrap/install-nixos.sh" "$@"
