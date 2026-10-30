# Disk layout for the `desktop` role. Default is a placeholder for eval / build-vm;
# the installer REGENERATES this file with the real device and the encrypt choice.
{ ... }:
{
  imports = [
    (import ../../disko/main.nix {
      device = "/dev/vda";
      encrypt = false;
    })
  ];
}
