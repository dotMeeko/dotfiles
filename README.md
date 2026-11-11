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
  nvim/init.lua       Neovim config (portable Lua)
linux/                Linux-only dotfiles
  niri/config.kdl     Niri compositor (incl. monitor modes and Noctalia keybinds)
  waynergy/           KVM client config (template) + Apple keycode table
  noctalia/           shell settings (symlink; its UI writes straight into the repo)
  systemd/            waynergy user unit + its graphical-session enablement link
  bin/, applications/ waynergy-toggle and its desktop entry
nix/                  NixOS (flake)
  flake.nix           hybrid: stable nixos-26.05 + nixpkgs-unstable overlay
  hosts/desktop/      per-role config (+ disko.nix: LUKS+Btrfs)
  disko/main.nix      reusable disk layout (LUKS + Btrfs)
  modules/            base system, Niri desktop, NVIDIA GPU
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
# asks: build (desktop), machine name, password, target disk (confirm by name),
# then partitions LUKS+Btrfs via disko and runs nixos-install. User `meeko` is fixed
# in the flake; the machine name is yours to pick (no hardcode). Reboot afterwards.
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

## Notes

- Disk is encrypted: **LUKS + Btrfs** (subvolumes `@root` `@home` `@nix` `@log`).
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
- **Order on a brand-new machine matters for the login screen.** greetd copies
  the waynergy config out of `~/.config/waynergy`, which does not exist until
  `dotter` has run once — so the *first* login screen has no remote input. Keep a
  local keyboard for that one login, run `dotter`, and every login screen after it
  accepts the Mac's keyboard. The copy is guarded, so a missing config can never
  stop the greeter from starting.
- **Desktop on Linux:** niri as the compositor, **Noctalia v5** as the shell (bar,
  launcher, notifications, lock screen) and **noctalia-greeter** as the login
  screen. It replaced DankMaterialShell, which owned parts of niri's own config —
  its monitor profiles left a phantom gap in the layout that made the remote mouse
  crawl, and its generated include silently overrode the keyboard layout toggle.
  Noctalia writes nothing into the niri config, so monitors are configured in
  `linux/niri/config.kdl` (mode and scale, deliberately without `position`).
  Noctalia's settings are managed, but not where its docs say: 5.3.0 leaves
  `~/.config/noctalia/` empty and writes everything to
  `~/.local/state/noctalia/settings.toml`, so that single file is the one mapped —
  as a symlink, so its settings UI writes into the repo directly. The rest of that
  directory stays local on purpose: it is runtime state, and `clipboard/index.enc`
  is clipboard history, which has no business in a public repo. Two values in the
  managed file are knowingly machine-bound — the wallpaper path points into
  `/nix/store` and so changes on every noctalia bump, and the lockscreen widget
  keys carry a connector name (`...@DP-3`).
- **Why dotter and not chezmoi:** chezmoi derives each target path from the source
  *filename* (`dot_config/...`), which is not configurable — upstream closed that
  request as wontfix. dotter keeps the repo layout free and writes the mapping out
  in `global.toml` instead. That is the trade: an explicit mapping file in exchange
  for paths that read like the paths they deploy to.
