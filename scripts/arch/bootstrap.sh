#!/usr/bin/env bash
# Bootstrap an Arch host: base-devel, then yay (AUR helper).
# Run from inside the cloned repo. Idempotent; safe to re-run.
set -euo pipefail

info() { printf '==> %s\n' "$*"; }
err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(uname -s)" == "Linux" ]] || err "Linux only."
have pacman || err "pacman not found; not an Arch-like system."
have git    || err "git not found; install it first: sudo pacman -S --needed git."

info "Priming sudo so makepkg won't pause mid-build."
sudo -v

# Per the official yay docs (https://github.com/jguer/yay): make sure the
# build deps (git + base-devel) are present, then clone and makepkg -si.
info "Ensuring git + base-devel via pacman."
sudo pacman -S --needed --noconfirm git base-devel

if ! have yay; then
	info "Bootstrapping yay from AUR."
	tmp=$(mktemp -d) || err "mktemp failed."
	trap 'rm -rf "$tmp"' EXIT
	git clone https://aur.archlinux.org/yay.git "$tmp/yay"
	(cd "$tmp/yay" && makepkg -si --noconfirm)
	have yay || err "yay install failed; see makepkg output above."
fi

info "Done. yay is ready. Next: scripts/arch/packages.sh to install packages."
