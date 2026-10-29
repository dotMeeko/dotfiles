# Role `desktop` — graphical workstation (Niri + NVIDIA).
# The machine NAME is not set here: it comes from the generated machine.nix
# (written by the installer), so renaming the machine never touches this file.
# hardware-configuration.nix is also generated on the machine. Both are imported
# only when present, so eval / build-vm work before they exist.
{ lib, ... }:
{
  imports =
    [
      ../../modules/base.nix
      ../../modules/desktop-niri.nix
      ../../modules/gpu-nvidia.nix
    ]
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix
    ++ lib.optional (builtins.pathExists ./machine.nix) ./machine.nix;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # build-vm only: headless, WSL2-friendly, throwaway login password.
  # Does not affect the real system.
  virtualisation.vmVariant = {
    users.users.meeko.hashedPasswordFile = lib.mkForce null;
    users.users.meeko.initialPassword = "changeme";
    virtualisation = {
      graphics = false; # serial console (ttyS0) so the boot can be read headless
      useNixStoreImage = true; # avoid WSL2's unreliable virtiofs host-store share
      writableStore = true; # writable store overlay so HM / nix-path registration works
    };
  };
}
