#!/usr/bin/env bash
#
# Interactive NixOS installer for bifrost.
#
# Run this from the NixOS live ISO. It lists the disks in this machine, makes
# you pick one, shows exactly what is on it, and only then partitions and
# installs.
#
#   sudo bash scripts/install.sh
#
# THIS ERASES THE DISK YOU SELECT. Nothing is touched until you have typed the
# confirmation, and the disk is never guessed for you.

set -euo pipefail

FLAKE_ATTR="bifrost"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'

die() { echo "${RED}error:${RESET} $*" >&2; exit 1; }
info() { echo "${GREEN}==>${RESET} $*"; }
warn() { echo "${YELLOW}warning:${RESET} $*"; }

# --- Preflight ---------------------------------------------------------------

[[ $EUID -eq 0 ]] || die "run as root: sudo bash scripts/install.sh"

[[ -d /sys/firmware/efi ]] || die \
  "not booted in UEFI mode. This config uses GRUB with efiSupport; boot the
   installer in UEFI mode, or switch to the BIOS setup described in README."

# --- Pick the disk -----------------------------------------------------------

info "Disks found in this machine:"
echo

mapfile -t DISKS < <(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}')
[[ ${#DISKS[@]} -gt 0 ]] || die "no disks detected"

for i in "${!DISKS[@]}"; do
  dev="${DISKS[$i]}"
  size=$(lsblk -dno SIZE "$dev")
  model=$(lsblk -dno MODEL "$dev" | xargs)
  printf "  %s[%d]%s %s  %s  %s\n" "$BOLD" "$((i+1))" "$RESET" "$dev" "$size" "${model:-unknown}"

  # Show what is on it, so a disk with data is obvious before it is erased.
  parts=$(lsblk -no NAME,SIZE,FSTYPE,LABEL "$dev" | tail -n +2 | sed 's/^/        /')
  if [[ -n "$parts" ]]; then
    echo "$parts"
  else
    echo "        (no partitions)"
  fi
  echo
done

read -rp "Install onto which disk? [1-${#DISKS[@]}] " choice
[[ "$choice" =~ ^[0-9]+$ ]] || die "not a number: $choice"
(( choice >= 1 && choice <= ${#DISKS[@]} )) || die "out of range: $choice"

TARGET="${DISKS[$((choice-1))]}"

# --- Resolve to a stable by-id path ------------------------------------------
# Kernel names are assigned in probe order and can move between boots; by-id is
# tied to the hardware. Partitions (…-part1) are filtered out.

# Every candidate points at the same disk, so any of them is safe to install
# to — but the confirmation screen below shows this path, and it should be the
# one a human can recognise. Rank them:
#   1. nvme-Samsung_SSD_990_PRO_2TB_S1A2  model and serial, unmistakable
#   2. wwn-0x5002538f31a1b2c3             opaque but stable
#   3. nvme-eui.0025385a91b2c3d4          opaque, and sorts after the good one
rank_by_id() {
  case "$1" in
    */nvme-eui.*|*/wwn-*) echo 2 ;;
    *) echo 1 ;;
  esac
}

BY_ID=""
BY_ID_RANK=99
shopt -s nullglob # an empty by-id dir must not yield a literal glob
for link in /dev/disk/by-id/*; do
  [[ "$link" == *-part[0-9]* ]] && continue
  [[ "$(readlink -f "$link")" == "$TARGET" ]] || continue

  r=$(rank_by_id "$link")
  if (( r < BY_ID_RANK )); then
    BY_ID="$link"
    BY_ID_RANK=$r
  fi
done
shopt -u nullglob

[[ -n "$BY_ID" ]] || die "could not resolve $TARGET to a /dev/disk/by-id path"

# --- Confirm -----------------------------------------------------------------

echo
echo "${RED}${BOLD}This will ERASE the following disk:${RESET}"
echo
echo "  device : $TARGET"
echo "  by-id  : $BY_ID"
echo "  size   : $(lsblk -dno SIZE "$TARGET")"
echo "  model  : $(lsblk -dno MODEL "$TARGET" | xargs)"
echo
echo "Everything on it is lost: partitions, filesystems, data."
echo

read -rp "Type ERASE to continue, anything else to abort: " confirm
[[ "$confirm" == "ERASE" ]] || die "aborted"

# --- Account -----------------------------------------------------------------
# Neither the username nor the password is hardcoded in this repo. The name
# goes into user.nix (which the config reads), the password hash goes onto the
# installed system, and neither one is committed.

info "Account to create"

USERNAME=""
while [[ -z "$USERNAME" ]]; do
  read -rp "  username: " USERNAME

  # Same rule useradd enforces: start with a letter or underscore, then
  # letters, digits, underscore or dash. Anything else is rejected later by
  # NixOS with a much less obvious error.
  if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    warn "must start with a lowercase letter or _, and contain only a-z 0-9 _ -"
    USERNAME=""
    continue
  fi
  if (( ${#USERNAME} > 32 )); then
    warn "too long (32 characters max)"
    USERNAME=""
    continue
  fi
  # Names that already exist on a NixOS system.
  case "$USERNAME" in
    root|nobody|messagebus|systemd-*|nixbld*|sshd|greeter)
      warn "'$USERNAME' is taken by the system, pick another"
      USERNAME=""
      ;;
  esac
done

read -rp "  full name [${USERNAME}]: " FULLNAME
FULLNAME=${FULLNAME:-$USERNAME}

# --- Password ----------------------------------------------------------------
# This repo is public, so no password or hash lives in it. We ask now and write
# the hash to the installed system's /etc/nixos-secrets/, which
# hashedPasswordFile reads on every activation — it never enters /nix/store.

info "Password for '$USERNAME'"

# mkpasswd is not in the minimal ISO. Wrap it so the flags reach mkpasswd and
# not nix-shell: `nix-shell --run mkpasswd -m yescrypt` would hand -m to
# nix-shell itself.
if command -v mkpasswd >/dev/null 2>&1; then
  hash_password() { mkpasswd -m yescrypt -s; }
else
  echo "  fetching mkpasswd"
  hash_password() { nix-shell -p mkpasswd --run 'mkpasswd -m yescrypt -s'; }
fi

PASS_HASH=""
while [[ -z "$PASS_HASH" ]]; do
  # -s keeps it off the screen; the prompt goes to stderr so it is visible
  # even though stdout is being captured.
  read -rsp "  password: " pw1; echo
  read -rsp "  again:    " pw2; echo

  if [[ -z "$pw1" ]]; then
    warn "empty password, try again"
    continue
  fi
  if [[ "$pw1" != "$pw2" ]]; then
    warn "they do not match, try again"
    continue
  fi
  if (( ${#pw1} < 8 )); then
    warn "shorter than 8 characters — you can log in locally with it, but this"
    warn "account is a sudoer, so pick something longer"
    read -rp "  use it anyway? [y/N] " short
    [[ "$short" == "y" || "$short" == "Y" ]] || continue
  fi

  # yescrypt is the current default; passed on stdin so it never reaches the
  # process list or the shell history.
  PASS_HASH=$(printf '%s' "$pw1" | hash_password) || die "mkpasswd failed"
done
unset pw1 pw2

[[ "$PASS_HASH" == \$* ]] || die "mkpasswd returned something that is not a hash"
info "Password recorded"

# --- Write user.nix ----------------------------------------------------------
# The config imports this for the username. Only the name lands here; the
# password hash goes to the installed system, never into the repo.

cat > "$REPO_DIR/user.nix" <<EOF
# Who this machine belongs to.
#
# scripts/install.sh asks for the username at install time and rewrites this
# file, so the name is not baked into the rest of the config. Change it here
# and rebuild if it ever needs to differ.
{
  username = "$USERNAME";

  # Shown in \`finger\`, greeters and the like. Cosmetic.
  description = "$FULLNAME";
}
EOF

info "Wrote user.nix for '$USERNAME'"

# Nix builds a flake from the git tree, so this has to be committed or the
# build still uses the old name.
if command -v git >/dev/null 2>&1 && git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$REPO_DIR" add user.nix
  git -C "$REPO_DIR" -c user.email=install@localhost -c user.name=installer \
    commit -q -m "user: $USERNAME" -- user.nix 2>/dev/null || true
fi

# --- Hardware check ----------------------------------------------------------
# The repo ships a fixed list of initrd modules. If this machine needs something
# else, initrd will not find the disk and the system will not boot — so compare
# and warn while it is still fixable.

info "Checking kernel modules against this hardware"
TMPCFG=$(mktemp -d)
nixos-generate-config --no-filesystems --root "$TMPCFG" >/dev/null 2>&1 || true
GENERATED="$TMPCFG/etc/nixos/hardware-configuration.nix"

if [[ -f "$GENERATED" ]]; then
  # sed, not `grep -oP`: PCRE is not compiled into the grep on the minimal ISO,
  # and a silent failure here would skip the check entirely.
  detected=$(sed -n 's/.*availableKernelModules = \[ \(.*\) \].*/\1/p' "$GENERATED")

  if [[ -n "$detected" ]]; then
    echo "  detected: $detected"
    missing=0
    for m in $detected; do
      m_clean=${m//\"/}
      if ! grep -q "\"$m_clean\"" "$REPO_DIR/hardware-configuration.nix"; then
        warn "module $m_clean was detected here but is NOT in hardware-configuration.nix"
        missing=1
      fi
    done
    if (( missing )); then
      echo
      warn "initrd may not find the disk without those. Add them to"
      warn "hardware-configuration.nix and commit before continuing."
      echo
      read -rp "Continue anyway? [y/N] " cont
      [[ "$cont" == "y" || "$cont" == "Y" ]] || die "aborted"
    else
      echo "  all detected modules are present in hardware-configuration.nix"
    fi
  else
    warn "could not read the detected module list; skipping this check"
  fi
fi
rm -rf "$TMPCFG"

# --- Uncommitted changes -----------------------------------------------------
# Nix evaluates a flake in a git repo from the git tree, not the working
# directory: uncommitted edits are silently ignored. That is a real trap right
# after the module warning above — you fix hardware-configuration.nix, the fix
# does not get used, and initrd still cannot find the disk.

if command -v git >/dev/null 2>&1 && git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  if [[ -n "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" ]]; then
    warn "the repo has uncommitted changes, and nix will IGNORE them"
    git -C "$REPO_DIR" status --short | sed 's/^/    /'
    echo
    echo "Commit them first (no push needed):"
    echo "    git -C $REPO_DIR add -A && git -C $REPO_DIR commit -m 'hardware fixes'"
    echo
    read -rp "Continue anyway, using the committed state? [y/N] " cont
    [[ "$cont" == "y" || "$cont" == "Y" ]] || die "aborted"
  fi
fi

# --- Install -----------------------------------------------------------------
# disko-install partitions, formats, mounts and installs in one step. The
# --disk flag overwrites the placeholder device in modules/disko.nix.

# Stage the password hash for --extra-files. disko-install copies these onto
# the target *before* running nixos-install, so the hash is in place by the
# time activation reads hashedPasswordFile.
SECRETS=$(mktemp -d)
trap 'rm -rf "$SECRETS"' EXIT
umask 077
printf '%s\n' "$PASS_HASH" > "$SECRETS/$USERNAME"
chmod 600 "$SECRETS/$USERNAME"

info "Partitioning and installing — this takes a while"
echo

nix --experimental-features "nix-command flakes" \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake "$REPO_DIR#$FLAKE_ATTR" \
  --disk main "$BY_ID" \
  --extra-files "$SECRETS/$USERNAME" "/etc/nixos-secrets/$USERNAME"

# --- Done --------------------------------------------------------------------

echo
info "${BOLD}Installed.${RESET}"
cat <<EOF

Next:
  1. reboot
  2. log in as $USERNAME, with the password you just set
  3. copy this repo to /etc/nixos-cfg so rebuilds have a home:
       sudo git clone <repo-url> /etc/nixos-cfg

SSH is key-only — password login is off. Add your public key to
users.users.\${user.username}.openssh.authorizedKeys.keys in configuration.nix
before you rely on being able to log in remotely.

Rebuild after that with:
  sudo nixos-rebuild switch --flake /etc/nixos-cfg#$FLAKE_ATTR

EOF
