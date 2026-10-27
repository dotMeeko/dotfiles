#!/usr/bin/env bash
# NixOS installer, run from the live ISO.
# Prompts for hostname, username, password and target disk; hashes the password;
# partitions the disk via disko (LUKS+Btrfs); generates hardware-configuration.nix;
# and installs the flake. The password hash is written to the installed system
# (/etc/secrets/user-password), never committed to this repo.
#
# Non-interactive (for tests): set INSTALL_NONINTERACTIVE=1 and
# INSTALL_HOSTNAME / INSTALL_USERNAME / INSTALL_PASSWORD / INSTALL_DISK.
# INSTALL_SKIP_NIXOS_INSTALL=1 stops after partition + hardware config (no install).
set -euo pipefail

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

# Heuristic: does this whole disk look like it holds Windows? (NTFS / Microsoft parts)
disk_looks_like_windows() {
  lsblk -no FSTYPE,PARTTYPENAME "$1" 2>/dev/null | grep -qiE 'ntfs|microsoft'
}

# Interactive, numbered disk picker with details, so SSD #1 vs #2 is obvious.
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
  read -rp "Select the disk to ERASE and install onto (number): " num
  { [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#DISKS[@]}" ]; } \
    || { echo "Invalid selection." >&2; exit 1; }
  disk="${DISKS[$((num - 1))]}"
}

# Final guard before the destructive step: show the target and require exact confirmation.
confirm_destroy() {
  echo
  echo "============================================================"
  echo " ABOUT TO ERASE AND REPARTITION:  $disk"
  echo "============================================================"
  lsblk -no NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$disk" | sed 's/^/    /'
  if disk_looks_like_windows "$disk"; then
    echo
    echo " WARNING: this disk looks like it CONTAINS WINDOWS (NTFS/Microsoft)."
    echo "          Picking it will destroy your Windows install."
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
  hostname="${INSTALL_HOSTNAME:?set INSTALL_HOSTNAME}"
  username="${INSTALL_USERNAME:?set INSTALL_USERNAME}"
  password="${INSTALL_PASSWORD:?set INSTALL_PASSWORD}"
  disk="${INSTALL_DISK:?set INSTALL_DISK}"
else
  read -rp "Hostname: " hostname
  read -rp "Username: " username
  read -rsp "Password: " password; echo
  read -rsp "Repeat password: " password2; echo
  [ "$password" = "$password2" ] || { echo "Passwords differ" >&2; exit 1; }
  select_disk
fi

[ -b "$disk" ] || { echo "Target disk '$disk' is not a block device." >&2; exit 1; }

# Destructive-step confirmation (skipped only in non-interactive test mode).
[ "${INSTALL_NONINTERACTIVE:-0}" = "1" ] || confirm_destroy

msg "Hashing user password"
hash="$(printf '%s' "$password" | mkpasswd_cmd -m sha-512 -s)"

# The LUKS passphrase defaults to the user password; change here for a separate one.
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

msg "Generating hardware-configuration.nix for host '$hostname'"
nixos-generate-config --no-filesystems --root "$ROOT"
install -D "$ROOT/etc/nixos/hardware-configuration.nix" \
  "$FLAKE_DIR/hosts/$hostname/hardware-configuration.nix"

if [ "${INSTALL_SKIP_NIXOS_INSTALL:-0}" = "1" ]; then
  msg "INSTALL_SKIP_NIXOS_INSTALL=1 — stopping before nixos-install"
  exit 0
fi

msg "Installing NixOS (.#$hostname)"
nixos-install --root "$ROOT" --flake "$FLAKE_DIR#$hostname" --no-root-passwd

msg "Done. Reboot, then: chezmoi init --apply <repo-url>"
