# LUKS + Btrfs disk layout for the `desktop` role.
# device = /dev/vda is a placeholder for eval/build-vm; the install script overrides
# it with the real target disk and supplies the LUKS passphrase (passwordFile).
# Filesystems are addressed by partlabel, so the placeholder device does not affect
# the installed system.
{ ... }:
{
  imports = [
    (import ../../disko/luks-btrfs.nix { device = "/dev/vda"; })
  ];
}
