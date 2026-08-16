{ ... }:

let
  disk = import ../disk.nix;
in
{
  # --- Declarative partitioning ----------------------------------------------
  #
  # Replaces partitioning by hand. disko creates the GPT table, the ESP, the
  # btrfs filesystem and every subvolume, and generates the NixOS fileSystems
  # entries from this same declaration — so the mounts can never drift out of
  # sync with the layout.
  #
  # THE TARGET IS NOT HARDCODED. It lives in disk.nix, which scripts/install.sh
  # rewrites from the disk you pick and commits before partitioning — the same
  # pattern as user.nix. A wrong value here would erase the wrong drive, so it
  # is never a real disk in the repo.
  #
  # (The `disko` command has no --disk flag — that is disko-install only — so
  # the device has to come from the config itself, hence disk.nix.)
  #
  # WHY by-id: kernel names (/dev/sda, /dev/nvme0n1) are handed out in probe
  # order and can swap between boots. by-id is tied to the hardware itself.

  disko.devices.disk.main = {
    type = "disk";
    device = disk.main;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" "-L" "nixos" ];

            # Same split as the rollback story needs: the system rolls back,
            # personal data stays where it is.
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              # snapper requires a subvolume literally named .snapshots INSIDE
              # the subvolume it manages — for a config on /home that means
              # /home/.snapshots, not /.snapshots.
              #
              # It is its own subvolume so that rolling @home back does not
              # take the snapshots with it: a snapshot stored inside the thing
              # it protects disappears exactly when it is needed.
              "@home-snapshots" = {
                mountpoint = "/home/.snapshots";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
