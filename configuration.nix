{ pkgs, ... }:

let
  user = import ./user.nix;
in
{
  # --- Boot loader -----------------------------------------------------------
  # GRUB in UEFI mode. Its menu is what makes NixOS rollbacks work: every
  # rebuild adds a generation entry, and booting an older one brings the whole
  # system config back. Personal files are untouched by this — see the btrfs
  # subvolume layout in modules/disko.nix.
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    # "nodev" is correct for UEFI — GRUB goes to the ESP, not to a disk MBR.
    device = "nodev";
    # Keep plenty of generations in the menu; this is the actual safety net.
    configurationLimit = 30;
    # Copy kernels onto the ESP instead of pointing GRUB into the store. With
    # a root on btrfs subvolumes this avoids GRUB having to resolve store paths
    # across subvolume boundaries, which is a classic way to end up unbootable.
    copyKernels = true;
  };

  # For a Legacy/BIOS machine instead: set efiSupport = false, point `device`
  # at the disk itself (/dev/disk/by-id/…, the whole disk not a partition),
  # drop the two boot.loader.efi lines below, and add an EF02 BIOS boot
  # partition to modules/disko.nix.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # --- Networking ------------------------------------------------------------
  networking.hostName = "bifrost";
  networking.networkmanager.enable = true;

  # --- Firmware and microcode ------------------------------------------------
  # Real hardware needs blobs for Wi-Fi, Bluetooth and GPU.
  hardware.enableRedistributableFirmware = true;
  # Ryzen 7 7800X3D.
  hardware.cpu.amd.updateMicrocode = true;

  # --- Locale and time -------------------------------------------------------
  # Kyiv time, but the whole system stays in English.
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  # Second layout for typing only — Alt+Shift switches, console included.
  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
  };
  console.useXkbConfig = true;

  # --- User ------------------------------------------------------------------
  # zsh has to be enabled system-wide as well, otherwise it is not a valid
  # login shell and the user's home-manager zsh config never gets used.
  programs.zsh.enable = true;

  # The username comes from user.nix, which scripts/install.sh writes from what
  # you type at install time — it is not hardcoded anywhere else.
  #
  # Passwords are NOT in this repository either; it is public. The installer
  # hashes the password and writes it to /etc/nixos-secrets/, and
  # hashedPasswordFile reads that on every activation, so the store never sees
  # it.
  #
  # To change the password later run `passwd` (mutableUsers is on, so it
  # sticks), or regenerate the hash:
  #   mkpasswd -m yescrypt | sudo tee /etc/nixos-secrets/<username>
  users.users.${user.username} = {
    isNormalUser = true;
    inherit (user) description;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    hashedPasswordFile = "/etc/nixos-secrets/${user.username}";
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... you@valhalla" ];
  };

  # root has no password: log in as the normal user and use sudo.
  users.users.root.hashedPassword = "!";

  # --- SSH -------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      # Keys only. A public repo plus password auth is how machines get owned;
      # put your key in authorizedKeys above and this stays shut.
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # --- Unfree packages -------------------------------------------------------
  # The NVIDIA driver stays unfree even with open kernel modules, because its
  # userspace part remains proprietary.
  nixpkgs.config.allowUnfree = true;

  # --- Power and disks -------------------------------------------------------
  # TRIM for SSDs.
  services.fstrim.enable = true;

  # --- Nix -------------------------------------------------------------------
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --- Base packages ---------------------------------------------------------
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    pciutils
    usbutils
    # btrfs-progs comes in automatically via system.fsPackages.
    compsize # shows how much btrfs compression actually saves
  ];

  # DO NOT change after install. This is not the NixOS version but a marker for
  # stateful data compatibility (databases, config formats). Keep the value the
  # system was originally installed with.
  system.stateVersion = "26.11";
}
