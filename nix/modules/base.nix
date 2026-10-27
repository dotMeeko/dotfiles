# Reusable system base — shared by all NixOS hosts.
{ ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  # Locale and time
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  # Networking
  networking.networkmanager.enable = true;

  # User. On a real install the password is set by the install script (dot-3)
  # as a hashed-password file written to the installed system (never in this repo).
  # The VM variant (hosts/desktop) overrides it with a throwaway password for tests.
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

  # Do not change after the system's first install.
  system.stateVersion = "26.05";
}
