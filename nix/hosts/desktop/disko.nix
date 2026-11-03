{ ... }:
{
  imports = [
    (import ../../disko/main.nix {
      device = "/dev/sda";
      encrypt = false;
    })
  ];
}
