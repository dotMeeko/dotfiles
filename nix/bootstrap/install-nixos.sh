#!/usr/bin/env bash
# NixOS installer, run from the live ISO (usually via ./install.sh in the repo root).
# Asks: build/role, machine name, user name, user password, encrypt? (+ disk password),
# target disk. Nothing is hardcoded — the role is the flake attribute; machine name,
# user name and disk layout are generated into hosts/<role>/{machine,user,disko}.nix.
#
# Non-interactive (tests): INSTALL_NONINTERACTIVE=1 + INSTALL_ROLE / INSTALL_HOSTNAME /
# INSTALL_USER / INSTALL_PASSWORD / INSTALL_DISK / INSTALL_ENCRYPT(0|1) [INSTALL_DISKPASS]
# [INSTALL_FULLNAME].
# INSTALL_SKIP_NIXOS_INSTALL=1 stops before nixos-install.
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

disk_looks_like_windows() {
  lsblk -no FSTYPE,PARTTYPENAME "$1" 2>/dev/null | grep -qiE 'ntfs|microsoft'
}

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

# Read a password twice (loops until they match and are non-empty). Result in $REPLY_PW.
read_password_twice() {
  local prompt="$1" p1 p2
  while :; do
    read -rsp "$prompt: " p1; echo
    [ -n "$p1" ] || { echo "Cannot be empty, try again." >&2; continue; }
    read -rsp "Repeat: " p2; echo
    [ "$p1" = "$p2" ] && { REPLY_PW="$p1"; return; }
    echo "Do not match, try again." >&2
  done
}

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
  echo " Build '$role', machine '$machine', user '$username', encrypt=$encrypt"
  echo " ABOUT TO ERASE AND REPARTITION:  $disk"
  echo "============================================================"
  lsblk -no NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$disk" | sed 's/^/    /'
  disk_looks_like_windows "$disk" && echo && echo " WARNING: this disk looks like it CONTAINS WINDOWS (NTFS/Microsoft)."
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
  username="${INSTALL_USER:?set INSTALL_USER}"
  fullname="${INSTALL_FULLNAME:-}"
  password="${INSTALL_PASSWORD:?set INSTALL_PASSWORD}"
  disk="${INSTALL_DISK:?set INSTALL_DISK}"
  [ "${INSTALL_ENCRYPT:-0}" = "1" ] && encrypt=true || encrypt=false
  diskpass="${INSTALL_DISKPASS:-}"
else
  select_role
  while :; do read -rp "Machine name (hostname): " machine; [ -n "$machine" ] && break; echo "Required, try again." >&2; done
  while :; do read -rp "User name: " username; [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] && break; echo "Invalid user name (lowercase letters/digits/_/-), try again." >&2; done
  read -rp "Full name (shown on the login screen, optional): " fullname
  read_password_twice "Password for $username"; password="$REPLY_PW"
  read -rp "Encrypt the disk? (asks a separate disk password at every boot) [y/N]: " enc
  case "$enc" in [yY]*) encrypt=true;; *) encrypt=false;; esac
  if [ "$encrypt" = true ]; then
    read_password_twice "Disk encryption password (separate from the user password)"; diskpass="$REPLY_PW"
  else
    diskpass=""
  fi
  select_disk
fi

[ -d "$FLAKE_DIR/hosts/$role" ] || { echo "Unknown build '$role' (no hosts/$role)" >&2; exit 1; }
[ -b "$disk" ] || { echo "Target disk '$disk' is not a block device." >&2; exit 1; }

[ "${INSTALL_NONINTERACTIVE:-0}" = "1" ] || confirm_destroy

msg "Hashing user password"
hash="$(printf '%s' "$password" | mkpasswd_cmd -m sha-512 -s)"

# Partition. Encrypted installs pass a LUKS passphrase file to disko.
disko_args=(--mode disko --root-mountpoint "$ROOT" --argstr device "$disk" --arg encrypt "$encrypt")
if [ "$encrypt" = true ]; then
  luks_pw="$(mktemp)"
  trap 'rm -f "$luks_pw"' EXIT
  printf '%s' "$diskpass" > "$luks_pw"
  disko_args+=(--argstr passwordFile "$luks_pw")
fi

msg "Partitioning $disk via disko (Btrfs$([ "$encrypt" = true ] && echo ' + LUKS'))"
disko_cmd "${disko_args[@]}" "$FLAKE_DIR/disko/main.nix"

msg "Writing hashed user password to $ROOT/etc/secrets/user-password"
install -D -m600 /dev/null "$ROOT/etc/secrets/user-password"
printf '%s\n' "$hash" > "$ROOT/etc/secrets/user-password"

msg "Generating per-machine files for build '$role' (name '$machine', user '$username')"
nixos-generate-config --no-filesystems --root "$ROOT"
install -D "$ROOT/etc/nixos/hardware-configuration.nix" "$FLAKE_DIR/hosts/$role/hardware-configuration.nix"
printf '{ networking.hostName = "%s"; }\n' "$machine" > "$FLAKE_DIR/hosts/$role/machine.nix"
printf '{ my.username = "%s"; my.fullName = "%s"; }\n' "$username" "$fullname" > "$FLAKE_DIR/hosts/$role/user.nix"
cat > "$FLAKE_DIR/hosts/$role/disko.nix" <<EOF
{ ... }:
{
  imports = [
    (import ../../disko/main.nix {
      device = "$disk";
      encrypt = $encrypt;
    })
  ];
}
EOF

if [ "${INSTALL_SKIP_NIXOS_INSTALL:-0}" = "1" ]; then
  msg "INSTALL_SKIP_NIXOS_INSTALL=1 — stopping before nixos-install"
  exit 0
fi

# `path:` makes Nix read the directory as-is (incl. the just-generated untracked files).
msg "Installing NixOS (build '$role', machine '$machine')"
nixos-install --root "$ROOT" --flake "path:$FLAKE_DIR#$role" --no-root-passwd

msg "Done. Reboot, then: chezmoi init --apply dotMeeko/dotfiles"
