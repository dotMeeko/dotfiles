# dotfiles

Cross-platform dotfiles for **NixOS**, **macOS** and **Windows**.

**Split of responsibilities:** Nix installs packages and builds the NixOS system;
Homebrew does packages on macOS; winget on Windows. **chezmoi owns all
dotfiles** on every OS — configs stay plain and portable (no Nix needed to edit them).

## Layout

```
.chezmoiroot          -> "home" (chezmoi source lives in home/)
home/                 chezmoi source, applied on all OSes
  dot_bashrc          ~/.bashrc
  dot_gitconfig.tmpl  ~/.gitconfig (per-OS template)
  dot_config/nvim/    Neovim config (portable Lua)
  .chezmoiignore      per-OS include/exclude
  Documents/PowerShell/   Windows PowerShell profile
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
```

## Install

**NixOS** (from the live ISO):

```sh
git clone https://github.com/dotMeeko/dotfiles.git && cd dotfiles
./install.sh
# asks: build (desktop), machine name, password, target disk (confirm by name),
# then partitions LUKS+Btrfs via disko and runs nixos-install. User `meeko` is fixed
# in the flake; the machine name is yours to pick (no hardcode). Reboot afterwards.
```

Then, on any OS, lay down the dotfiles:

```sh
chezmoi init --apply dotMeeko/dotfiles
```

On Linux this asks once for the **Deskflow server address** (the Mac) and stores
it in `~/.config/chezmoi/chezmoi.toml`, which is never committed — the answer is
network-specific and this repo is public. Leave it empty to skip: everything else
still applies and only the keyboard/mouse sharing stays idle until it is filled in.

- **macOS:** `chezmoi init --apply dotMeeko/dotfiles`, then
  `brew bundle --file ~/.local/share/chezmoi/macos/Brewfile`.
- **Windows:** `winget install twpayne.chezmoi`, then `chezmoi init --apply dotMeeko/dotfiles`,
  then `pwsh -File %USERPROFILE%\.local\share\chezmoi\windows\packages.ps1` for the rest of the
  software (`-WhatIf` lists it without installing).

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
  Client config: `home/dot_config/waynergy/`. Greeter wiring:
  `nix/modules/desktop-niri.nix`.
- **Order on a brand-new machine matters for the login screen.** greetd copies
  the waynergy config out of `~/.config/waynergy`, which does not exist until
  chezmoi has run once — so the *first* login screen has no remote input. Keep a
  local keyboard for that one login, run `chezmoi init --apply`, and every login
  screen after it accepts the Mac's keyboard. The copy is guarded, so a missing
  config can never stop the greeter from starting.
