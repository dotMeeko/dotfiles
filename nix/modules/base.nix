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
  # as a hash via users.users.<name>.hashedPassword; this is a temporary VM password.
  users.users.meeko = {
    isNormalUser = true;
    description = "Meeko";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialPassword = "changeme";
  };

  services.openssh.enable = true;

  # sudo for the wheel group, password required
  security.sudo.wheelNeedsPassword = true;

  # Do not change after the system's first install.
  system.stateVersion = "26.05";
}
