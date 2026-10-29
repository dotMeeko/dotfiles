#!/usr/bin/env bash
# NixOS installer, run from the live ISO (usually via ./install.sh in the repo root).
# Asks: build/role (desktop/server...), machine name, password, target disk.
# The role is the flake attribute (nixosConfigurations.<role>); the machine name is a
# parameter written to hosts/<role>/machine.nix, so renaming the machine never touches
# the flake structure.
# Steps: pick role -> name -> password -> disk -> disko (LUKS+Btrfs) ->
# hardware-configuration.nix + machine.nix -> nixos-install.
#
# Non-interactive (tests): INSTALL_NONINTERACTIVE=1 + INSTALL_ROLE / INSTALL_HOSTNAME /
# INSTALL_PASSWORD / INSTALL_DISK. INSTALL_SKIP_NIXOS_INSTALL=1 stops before install.
set -euo pipefail

USERNAME="${INSTALL_USER:-meeko}" # must match the user defined in the flake

FLAKE_DIR="${FLAKE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="${ROOT:-/mnt}"

msg() { printf '\n>>> %s\n' "$*"; }

mkpasswd_cmd() {
  if command -v mkpasswd >/dev/null 2>&1; then
    mkpasswd "$@"
  else
    nix --experimental-features "nix-command flakes" run nixpkgs#mkpasswd -- "$@"
  fi
}

disko_cmd() {
  nix --experimental-features "nix-command flakes" run github:nix-community/disko -- "$@"
}

disk_looks_like_windows() {
  lsblk -no FSTYPE,PARTTYPENAME "$1" 2>/dev/null | grep -qiE 'ntfs|microsoft'
}

# Pick the build/role from the available hosts/<role> directories.
select_role() {
  mapfile -t ROLES < <(find "$FLAKE_DIR/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  [ "${#ROLES[@]}" -gt 0 ] || { echo "No roles under $FLAKE_DIR/hosts" >&2; exit 1; }
  if [ "${#ROLES[@]}" -eq 1 ]; then
    role="${ROLES[0]}"
    echo "Build: $role (only one available)"
    return
  fi
  echo "Available builds:"
  local i=1
  for r in "${ROLES[@]}"; do printf "  [%d] %s\n" "$i" "$r"; i=$((i + 1)); done
  local num
  while :; do
    read -rp "Select build (number): " num
    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#ROLES[@]}" ]; then break; fi
    echo "Invalid selection, try again." >&2
  done
  role="${ROLES[$((num - 1))]}"
}

# Numbered disk picker with details, so SSD #1 vs #2 is obvious.
select_disk() {
  mapfile -t DISKS < <(lsblk -dpno NAME | grep -vE '/dev/(loop|sr|ram|zram|fd)')
  [ "${#DISKS[@]}" -gt 0 ] || { echo "No disks found." >&2; exit 1; }
  echo "Detected disks:"
  echo
  local i=1 d info warn
  for d in "${DISKS[@]}"; do
    info="$(lsblk -dno SIZE,MODEL,SERIAL "$d" | tr -s ' ')"
    warn=""
    disk_looks_like_windows "$d" && warn="   <-- looks like WINDOWS — do NOT pick unless you are sure"
    printf "  [%d] %s  —  %s%s\n" "$i" "$d" "$info" "$warn"
    lsblk -no NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$d" | sed 's/^/          /'
    echo
    i=$((i + 1))
  done
  local num
  while :; do
    read -rp "Select the disk to ERASE and install onto (number): " num
    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#DISKS[@]}" ]; then break; fi
    echo "Invalid selection, try again." >&2
  done
  disk="${DISKS[$((num - 1))]}"
}

confirm_destroy() {
  echo
  echo "============================================================"
  echo " Build '$role', machine '$machine', user '$USERNAME'"
  echo " ABOUT TO ERASE AND REPARTITION:  $disk"
  echo "============================================================"
  lsblk -no NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$disk" | sed 's/^/    /'
  if disk_looks_like_windows "$disk"; then
    echo
    echo " WARNING: this disk looks like it CONTAINS WINDOWS (NTFS/Microsoft)."
  fi
  echo
  echo " ALL DATA ON $disk WILL BE PERMANENTLY LOST."
  local base ans
  base="$(basename "$disk")"
  read -rp " Type the disk name '$base' to confirm (anything else aborts): " ans
  [ "$ans" = "$base" ] || { echo "Confirmation failed — aborting, nothing was changed." >&2; exit 1; }
}

# --- gather inputs ---
if [ "${INSTALL_NONINTERACTIVE:-0}" = "1" ]; then
  role="${INSTALL_ROLE:?set INSTALL_ROLE}"
  machine="${INSTALL_HOSTNAME:?set INSTALL_HOSTNAME}"
  password="${INSTALL_PASSWORD:?set INSTALL_PASSWORD}"
  disk="${INSTALL_DISK:?set INSTALL_DISK}"
else
  select_role
  while :; do
    read -rp "Machine name (hostname): " machine
    [ -n "$machine" ] && break
    echo "Machine name is required, try again." >&2
  done
  while :; do
    read -rsp "Password for $USERNAME (also unlocks the disk): " password; echo
    [ -n "$password" ] || { echo "Password cannot be empty, try again." >&2; continue; }
    read -rsp "Repeat password: " password2; echo
    [ "$password" = "$password2" ] && break
    echo "Passwords do not match, try again." >&2
  done
  select_disk
fi

[ -d "$FLAKE_DIR/hosts/$role" ] || { echo "Unknown build '$role' (no hosts/$role)" >&2; exit 1; }
[ -b "$disk" ] || { echo "Target disk '$disk' is not a block device." >&2; exit 1; }

[ "${INSTALL_NONINTERACTIVE:-0}" = "1" ] || confirm_destroy

msg "Hashing password"
hash="$(printf '%s' "$password" | mkpasswd_cmd -m sha-512 -s)"

luks_pw="$(mktemp)"
trap 'rm -f "$luks_pw"' EXIT
printf '%s' "$password" > "$luks_pw"

msg "Partitioning $disk via disko (LUKS + Btrfs)"
disko_cmd --mode disko --root-mountpoint "$ROOT" \
  --argstr device "$disk" --argstr passwordFile "$luks_pw" \
  "$FLAKE_DIR/disko/luks-btrfs.nix"

msg "Writing hashed password to $ROOT/etc/secrets/user-password"
install -D -m600 /dev/null "$ROOT/etc/secrets/user-password"
printf '%s\n' "$hash" > "$ROOT/etc/secrets/user-password"

msg "Generating hardware-configuration.nix and machine.nix (name '$machine')"
nixos-generate-config --no-filesystems --root "$ROOT"
install -D "$ROOT/etc/nixos/hardware-configuration.nix" \
  "$FLAKE_DIR/hosts/$role/hardware-configuration.nix"
printf '{ networking.hostName = "%s"; }\n' "$machine" > "$FLAKE_DIR/hosts/$role/machine.nix"

if [ "${INSTALL_SKIP_NIXOS_INSTALL:-0}" = "1" ]; then
  msg "INSTALL_SKIP_NIXOS_INSTALL=1 — stopping before nixos-install"
  exit 0
fi

# `path:` makes Nix read the directory as-is (incl. the just-generated untracked
# files), instead of only git-committed content.
msg "Installing NixOS (build '$role', machine '$machine')"
nixos-install --root "$ROOT" --flake "path:$FLAKE_DIR#$role" --no-root-passwd

msg "Done. Reboot, then: chezmoi init --apply dotMeeko/dotfiles"
