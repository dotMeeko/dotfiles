# Host `desktop` — the real dual-boot PC (SSD #2 = NixOS).
# Disk layout: ./disko.nix (LUKS + Btrfs). Filesystems come from disko, not here.
# hardware-configuration.nix is generated on the machine by the install script and
# imported only when present (so eval / build-vm work before it exists).
{ lib, ... }:
{
  imports = [
    ../../modules/base.nix
    ../../modules/desktop-niri.nix
    ../../modules/gpu-nvidia.nix
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  networking.hostName = "desktop";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # build-vm only: headless, WSL2-friendly, throwaway login password.
  # Does not affect the real system.
  virtualisation.vmVariant = {
    # No hashedPasswordFile in the VM; use a throwaway password so login works.
    users.users.meeko.hashedPasswordFile = lib.mkForce null;
    users.users.meeko.initialPassword = "changeme";
    virtualisation = {
      graphics = false; # serial console (ttyS0) so the boot can be read headless
      useNixStoreImage = true; # avoid WSL2's unreliable virtiofs host-store share
      writableStore = true; # writable store overlay so HM / nix-path registration works
    };
  };
}
