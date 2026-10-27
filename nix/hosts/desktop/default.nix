# Host `desktop` — the real dual-boot PC (SSD #2 = NixOS).
# Tested in QEMU via `nixos-rebuild build-vm .#desktop` (no separate test host).
{ ... }:
{
  imports = [ ../../modules/base.nix ];

  networking.hostName = "desktop";

  # Placeholder root filesystem. Replaced by disko (dot-2) and the real
  # hardware-configuration.nix generated on the machine (`nixos-generate-config`).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # build-vm only: headless, WSL2-friendly settings. Does not affect the real system.
  virtualisation.vmVariant.virtualisation = {
    graphics = false; # serial console (ttyS0) so the boot can be read headless
    # WSL2's virtiofs host share is unreliable; pack the Nix store into a disk
    # image instead of sharing the host store over virtiofs.
    useNixStoreImage = true;
    writableStore = false;
  };
}
