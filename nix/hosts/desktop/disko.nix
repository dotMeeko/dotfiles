# LUKS + Btrfs disk layout for `desktop`.
# device = /dev/vda for VM tests; the install script (dot-8) overrides it with the
# real target disk and supplies the LUKS passphrase (passwordFile).
{ ... }:
{
  imports = [
    (import ../../disko/luks-btrfs.nix { device = "/dev/vda"; })
  ];
}
