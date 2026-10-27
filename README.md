# dotfiles

Cross-platform dotfiles for **NixOS**, **macOS** and **Windows**.

**Split of responsibilities:** Nix installs packages and builds the NixOS system;
Homebrew does packages on macOS; scoop/winget on Windows. **chezmoi owns all
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
  hosts/desktop/      host config + LUKS+Btrfs disko layout
  modules/            base system, Niri desktop
  home/packages.nix   home-manager: home.packages only
  bootstrap/install-nixos.sh   guided installer (disk pick + confirm)
macos/Brewfile        macOS packages
```

## Install

**NixOS** (from the live ISO):

```sh
git clone <repo-url> dotfiles && cd dotfiles
sudo nix --experimental-features "nix-command flakes" \
  run nixpkgs#bash -- nix/bootstrap/install-nixos.sh
# prompts hostname/username/password, pick the target disk (confirm by name),
# partitions LUKS+Btrfs via disko, then nixos-install. Reboot afterwards.
```

Then, on any OS, lay down the dotfiles:

```sh
chezmoi init --apply <repo-url>
```

- **macOS:** `brew bundle --file macos/Brewfile`, then `chezmoi init --apply`.
- **Windows:** install chezmoi (scoop), then `chezmoi init --apply`.

## Notes

- Disk is encrypted: **LUKS + Btrfs** (subvolumes `@root` `@home` `@nix` `@log`).
- The user password hash is written to the installed machine
  (`/etc/secrets/user-password`), never stored in this repo.
- The installer shows every disk with model/size and refuses to wipe one unless
  you type its name; disks that look like Windows (NTFS) are flagged.
