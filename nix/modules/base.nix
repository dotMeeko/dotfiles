# Reusable system base — shared by all NixOS hosts/roles.
{ config, lib, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  # Default machine name. Overridden by the generated hosts/<role>/machine.nix
  # (written by the installer) — renaming a machine is a one-line change.
  networking.hostName = lib.mkDefault "nixos";

  # Locale and time
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  # Networking
  networking.networkmanager.enable = true;

  # mDNS resolution, so peers can be reached by <name>.local instead of a DHCP
  # address that changes. macOS publishes its own .local name out of the box, so
  # waynergy can point at the Mac by name and survive a lease change.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Primary user. Name comes from config.my.username (set by the installer's user.nix).
  # The password hash is written by the installer to a file on the installed system,
  # never committed to this repo.
  users.users.${config.my.username} = {
    isNormalUser = true;
    # Display name (GECOS) shown by the greeter. Empty -> the login name is shown.
    description = config.my.fullName;
    extraGroups = [
      "wheel"
      "networkmanager"
      # waynergy's uinput backend needs to open /dev/uinput. See hardware.uinput below.
      "uinput"
    ];
    hashedPasswordFile = "/etc/secrets/user-password";
  };

  # This system is built from a flake, so the flake CLI has to work without
  # passing --extra-experimental-features on every invocation.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.openssh.enable = true;

  # sudo for the wheel group, password required
  security.sudo.wheelNeedsPassword = true;

  # Hardware basics (this machine: AMD Ryzen 7800X3D).
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # Compressed RAM swap (no disk swap, no hibernation).
  zramSwap.enable = true;

  # Do not change after the system's first install.
  system.stateVersion = "26.05";
}
