# Reusable disk layout: GPT + ESP + Btrfs (snapshot-ready subvolumes), with OPTIONAL
# LUKS encryption. `encrypt` is chosen at install time.
#
# Subvolumes:
#   @ -> /   @home -> /home   @nix -> /nix (never snapshot)
#   @snapshots -> /.snapshots   @log -> /var/log
#
# Args:
#   device       - target disk (/dev/vda in a VM, /dev/nvme0n1 or /dev/sda on hardware)
#   encrypt      - true => wrap Btrfs in LUKS2 (asks a separate disk password at boot)
#   passwordFile - file with the LUKS passphrase for non-interactive partitioning
{
  device,
  encrypt ? false,
  passwordFile ? null,
  ...
}:
let
  opts = [
    "compress=zstd"
    "noatime"
    "discard=async"
  ];
  btrfs = {
    type = "btrfs";
    extraArgs = [ "-f" ];
    subvolumes = {
      "@" = {
        mountpoint = "/";
        mountOptions = opts;
      };
      "@home" = {
        mountpoint = "/home";
        mountOptions = opts;
      };
      "@nix" = {
        mountpoint = "/nix";
        mountOptions = opts;
      };
      "@snapshots" = {
        mountpoint = "/.snapshots";
        mountOptions = opts;
      };
      "@log" = {
        mountpoint = "/var/log";
        mountOptions = opts;
      };
    };
  };
  luks = {
    type = "luks";
    name = "cryptroot";
    settings.allowDiscards = true;
    content = btrfs;
  } // (if passwordFile == null then { } else { inherit passwordFile; });
in
{
  disko.devices.disk.main = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = if encrypt then luks else btrfs;
        };
      };
    };
  };
}
