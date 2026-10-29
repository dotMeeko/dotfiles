# Reusable disk layout: GPT + ESP + LUKS -> Btrfs with a snapshot-ready subvolume
# layout (Arch/snapper convention, adapted for NixOS).
#
# Subvolumes:
#   @          -> /            (rolled back by snapper)
#   @home      -> /home        (its own snapshots)
#   @nix       -> /nix         (Nix store — NEVER snapshot/rollback)
#   @snapshots -> /.snapshots  (snapper snapshot storage)
#   @log       -> /var/log     (survives a root rollback)
#
# Args:
#   device       - target disk (e.g. /dev/vda in a VM, /dev/nvme0n1 on real hardware)
#   passwordFile - optional file with the LUKS passphrase for non-interactive runs
#                  (install script / tests); when null, disko prompts interactively.
{
  device,
  passwordFile ? null,
  ...
}:
let
  # Shared mount options for all Btrfs subvolumes.
  opts = [
    "compress=zstd"
    "noatime"
    "discard=async"
  ];
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
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
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
          } // (if passwordFile == null then { } else { inherit passwordFile; });
        };
      };
    };
  };
}
