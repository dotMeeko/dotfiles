# Which disk bifrost installs onto.
#
# scripts/install.sh rewrites this at install time from the disk you pick, then
# commits it — the same pattern as user.nix, so the target is never hardcoded
# and a wrong value cannot erase the wrong drive. modules/disko.nix reads it.
#
# by-id, not /dev/sda or /dev/nvme0n1: kernel names are handed out in probe
# order and can move between boots; by-id is tied to the hardware.
{
  main = "/dev/disk/by-id/PLACEHOLDER-set-by-install.sh";
}
