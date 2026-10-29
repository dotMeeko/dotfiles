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
  hosts/desktop/      per-role config (+ disko.nix: LUKS+Btrfs)
  disko/luks-btrfs.nix   reusable disk layout
  modules/            base system, Niri desktop, NVIDIA GPU
  home/packages.nix   home-manager: home.packages only
  bootstrap/install-nixos.sh   guided installer (disk pick + confirm)
macos/Brewfile        macOS packages
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

- **macOS:** `chezmoi init --apply dotMeeko/dotfiles`, then `brew bundle --file ~/.local/share/chezmoi/macos/Brewfile`.
- **Windows:** install chezmoi (scoop), then `chezmoi init --apply dotMeeko/dotfiles`.

## Notes

- Disk is encrypted: **LUKS + Btrfs** (subvolumes `@root` `@home` `@nix` `@log`).
- The user password hash is written to the installed machine
  (`/etc/secrets/user-password`), never stored in this repo.
- The installer shows every disk with model/size and refuses to wipe one unless
  you type its name; disks that look like Windows (NTFS) are flagged.
