# dotfiles

| Host       | OS      | Managed by           |
|------------|---------|----------------------|
| `bifrost`  | NixOS   | flake + home-manager |
| `valhalla` | macOS   | chezmoi + Homebrew   |
| `midgard`  | Windows | chezmoi + WinGet     |

Nix runs on `bifrost` only. The other two use chezmoi for dotfiles and their
native package manager for software.

`bifrost` tracks **NixOS 26.05** (stable), not `nixos-unstable`. nixpkgs and
home-manager are pinned to the same release branch — mixing them breaks in
non-obvious ways. Bump both together when moving to the next release.

## Install

**NixOS** — from the live ISO, booted in UEFI mode. Lists the disks, you pick
one, it asks for a username and password, then partitions and installs.

```bash
nix-shell -p git --run 'git clone <repo-url> /tmp/cfg' && sudo bash /tmp/cfg/scripts/install.sh
```

The live ISO keeps `/nix/store` in a tmpfs sized at half the RAM, and this
config is large enough to fill it — the build then dies with `No space left on
device` (it is RAM, not the target disk, that ran out). `disko-install` builds
the system in the live environment before copying it to disk, so the ceiling is
RAM, not the 200 GB target. On a machine with plenty of memory, raise the store
limit to use the free RAM:

```bash
sudo mount -o remount,size=14G /nix/.rw-store
```

With little RAM (e.g. an 8 GB VM), give the build somewhere to spill by adding a
scratch disk and turning it into swap before running the installer:

```bash
lsblk                          # find the empty scratch disk, NOT the target
sudo mkswap /dev/<scratch>
sudo swapon /dev/<scratch>
sudo mount -o remount,size=40G /nix/.rw-store
```

A swap file will not help: the live root is itself in RAM, and the target disk
is wiped by `disko-install` mid-run — the swap has to be on a separate disk.

**macOS** — installs chezmoi, then Homebrew and the packages on first apply.

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply <repo-url>
```

**Windows** — from an elevated PowerShell.

```powershell
irm https://raw.githubusercontent.com/dotMeeko/nixos/main/windows/bootstrap.ps1 | iex
```

## Rebuild

```bash
sudo nixos-rebuild switch --flake /etc/nixos-cfg#bifrost   # bifrost
chezmoi update --apply                                     # valhalla, midgard
```

Rolling back on NixOS means picking an older generation in the GRUB menu.
`/home` is a separate btrfs subvolume, so it never rolls back with the system;
use `snapper -c home list` to recover files instead.

## Users and passwords

Nothing secret is in this repo. On `bifrost` the installer asks for a username
and password: the name goes into `user.nix`, the password hash to
`/etc/nixos-secrets/<name>` on the installed system, which
`hashedPasswordFile` reads on each activation — so it never enters the Nix
store. Change it later with `passwd`, or:

```bash
mkpasswd -m yescrypt | sudo tee /etc/nixos-secrets/$USER
```

SSH is key-only; add your public key to `configuration.nix` before relying on
remote login.

## Keeping the machines in sync

`home/common.nix` (bifrost) and `chezmoi/.chezmoidata/packages.yaml` (valhalla,
midgard) list the same tools for different package managers. They are synced by
hand — change one, change the other.
