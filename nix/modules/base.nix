# Reusable system base — shared by all NixOS hosts/roles.
{ lib, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  # Default machine name. Overridden by the generated hosts/<role>/machine.nix
  # (written by the installer) — so renaming a machine is a one-line change, not
  # a structural one.
  networking.hostName = lib.mkDefault "nixos";

  # Locale and time
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  # Networking
  networking.networkmanager.enable = true;

  # User. The real password hash is written by the install script to a file on the
  # installed system — never committed to this (public) repo. The VM variant
  # overrides this with a throwaway password for headless boot tests.
  users.users.meeko = {
    isNormalUser = true;
    description = "Meeko";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    hashedPasswordFile = "/etc/secrets/user-password";
  };

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
