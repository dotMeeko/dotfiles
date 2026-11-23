# dotfiles

Cross-platform dotfiles for **NixOS**, **macOS** and **Windows**.

**Split of responsibilities:** Nix installs packages and builds the NixOS system;
Homebrew does packages on macOS; winget on Windows. **dotter owns all dotfiles**
on every OS — configs stay plain and portable (no Nix needed to edit them).

## Layout

```
.dotter/global.toml   what goes where (committed) — the whole mapping
.dotter/local.toml    this machine's packages + variables (gitignored)
.dotter/local.toml.example   copy it to local.toml on a new machine
shared/               dotfiles for every OS
  bashrc              ~/.bashrc
  gitconfig           ~/.gitconfig (template; Windows bits gated on a variable)
  nvim/              Neovim — LazyVim (whole dir -> ~/.config/nvim; lazy-lock.json pinned)
linux/                Linux-only dotfiles
  niri/config.kdl     Niri compositor (incl. monitor modes and DMS keybinds)
  waynergy/           KVM client config (template) + Apple keycode table
  systemd/            waynergy user unit + its graphical-session enablement link
  bin/, applications/ waynergy-toggle and its desktop entry
nix/                  NixOS (flake)
  flake.nix           hybrid: stable nixos-26.05 + nixpkgs-unstable overlay
  hosts/desktop/      per-role config (+ generated machine/user/disko/hardware bits)
  disko/main.nix      reusable disk layout (Btrfs, optional LUKS)
  modules/            base system, Niri desktop, NVIDIA GPU, snapshots, docker
  home/packages.nix   home-manager: home.packages only
  pkgs/               packages missing from nixpkgs, pinned by release hash
  bootstrap/install-nixos.sh   guided installer (disk pick + confirm)
macos/Brewfile        macOS packages
macos/deskflow-server-options.conf
                      Deskflow server options for the Mac (applied by hand there)
windows/packages.ps1  Windows packages (winget)
windows/PowerShell/   PowerShell 7 profile
```

Entries in `global.toml` are **symlinks into this repo** by default, so editing a
file here takes effect immediately with no deploy step. Entries marked
`type = "template"` are generated instead — that is how a value can be used
without committing it.

## Install

**NixOS** (from the live ISO):

```sh
git clone https://github.com/dotMeeko/dotfiles.git && cd dotfiles
./install.sh
# asks: build (desktop), machine name, user name, password, encrypt? (y/N),
# target disk (confirm by name) — then partitions Btrfs (+ LUKS if chosen) via
# disko and runs nixos-install. Nothing is hardcoded: machine name, user and disk
# layout are generated into nix/hosts/<role>/. Reboot afterwards.
```

Then, on any OS, lay down the dotfiles from the repo root:

```sh
cp .dotter/local.toml.example .dotter/local.toml
$EDITOR .dotter/local.toml      # pick packages, set deskflow_server
dotter                          # --dry-run first if you want to see the plan
```

`local.toml` is gitignored, which is what keeps the **Deskflow server address**
(network-specific, and this repo is public) out of the history. Leave it empty to
skip: everything else still deploys and only the keyboard/mouse sharing sits idle.

- **macOS:** `brew install dotter`, then `brew bundle --file macos/Brewfile`.
- **Windows:** `winget install SuperCuber.Dotter`, then
  `pwsh -File windows\packages.ps1` for the rest of the software (`-WhatIf` lists
  it without installing). Note that Windows only allows symlinks with Developer
  Mode on or from an elevated shell — the Windows package deploys its one file as
  a template for that reason, and any entry can be switched the same way.

## Rebuild (NixOS)

Anything under `nix/` takes effect only after a rebuild. One flake output per
**role** (`nix/hosts/`); the only role so far is `desktop`:

```sh
sudo nixos-rebuild switch --flake ~/.dotfiles/nix#desktop
```

Swap `switch` for `boot` to apply on the next reboot instead, or `test` to try
a build that does not survive one. `nix flake update` (run inside `nix/`) bumps
the pinned inputs; the rebuild picks them up.

## Notes

- Disk layout: **Btrfs** (subvolumes `@` `@home` `@nix` `@snapshots` `@log`),
  optionally wrapped in **LUKS** — the installer asks; encryption costs a separate
  disk password at every boot.
- The user password hash is written to the installed machine
  (`/etc/secrets/user-password`), never stored in this repo.
- The installer shows every disk with model/size and refuses to wipe one unless
  you type its name; disks that look like Windows (NTFS) are flagged.
- **Keyboard and mouse come from the Mac** — Deskflow there as the server,
  `waynergy` here as the client (Synergy 1 protocol), injecting through
  `/dev/uinput`. Works both inside the session and **on the login screen**.
  uinput is not a shortcut: a Wayland greeter has no user session and nobody to
  approve a capture, so the RemoteDesktop portal cannot work there and no
  portal-based client — Synergy 3 included — can ever type at the login prompt.
  Client config: `linux/waynergy/`. Greeter wiring: `nix/modules/desktop-niri.nix`.
- **Point the client at the Mac by name, not by IP.** `deskflow-host
  <LocalHostName>.local` writes the address into `.dotter/local.toml` and
  re-renders the client config in one step. A name is resolved on every
  connection attempt (avahi/mDNS here, mDNSResponder on the Mac), so a new DHCP
  lease costs one reconnect; an IP in there silently rots into
  `connect: No route to host`, at the login screen as well. Run it again after a
  macOS reinstall, which is when the computer name itself changes.
- **Order on a brand-new machine matters for the login screen.** greetd copies
  the waynergy config out of `~/.config/waynergy`, which does not exist until
  `dotter` has run once — so the *first* login screen has no remote input. Keep a
  local keyboard for that one login, run `dotter`, and every login screen after it
  accepts the Mac's keyboard. The copy is guarded, so a missing config can never
  stop the greeter from starting.
- **Desktop on Linux:** niri as the compositor, **DMS — Dux Modular Shell** as the
  shell (bar, launcher, notifications, process list, notepad, lock screen) and
  **Dux Greeter** as the login screen. Both come from the upstream flakes
  (`duxlabs-dev/dux-shell/stable`, `duxlabs-dev/dux-greeter`), not nixpkgs, which
  still carries the 1.4.x line under the old `dms-shell` name. The project was
  DankMaterialShell until 2.0 (2026-10-20); the Nix attributes and options kept
  the old names — `homeModules.dank-material-shell`,
  `programs.dank-material-shell`, `programs.dms-greeter` — and that mismatch is
  upstream's, not a mistake here.
- **The shell gets no say over the niri config, and that is the whole
  arrangement.** A week on Noctalia bought exactly this lesson: the three failures
  of 2026-11-05 — a phantom gap in the monitor layout that made the remote mouse
  crawl, a dead keyboard-layout toggle, a drifting `include` line — all came from
  DMS owning pieces of `config.kdl` through its generated `dms/*.kdl` files.
  Swapping shells was the expensive way to fix that; not granting the includes is
  the cheap one. So: `includes.enable = false` in `nix/modules/home.nix`, no
  `include` line in `linux/niri/config.kdl`, monitors and keybinds written by hand
  in that file, and the shell's display auto-apply left off (it defaults off in
  2.1.2). Cost of the arrangement, paid knowingly: no wallpaper-derived colours or
  layout sync into niri's focus ring. Both files say this at the point where it
  matters.
- **The shell's own settings are not tracked** (`~/.config/dms/settings.json`). It
  is one blob mixing real settings with per-connector layouts, a weather location
  and whatever its integrations collect, rewritten on every click. The Noctalia
  equivalent was tracked for a week and mostly produced churn plus a `/nix/store`
  path that went stale on every bump.
- **Why dotter and not chezmoi:** chezmoi derives each target path from the source
  *filename* (`dot_config/...`), which is not configurable — upstream closed that
  request as wontfix. dotter keeps the repo layout free and writes the mapping out
  in `global.toml` instead. That is the trade: an explicit mapping file in exchange
  for paths that read like the paths they deploy to.
