{ ... }:

{
  # --- Declarative partitioning ----------------------------------------------
  #
  # Replaces partitioning by hand. disko creates the GPT table, the ESP, the
  # btrfs filesystem and every subvolume, and generates the NixOS fileSystems
  # entries from this same declaration — so the mounts can never drift out of
  # sync with the layout.
  #
  # THE DEVICE BELOW IS A PLACEHOLDER. This machine has two drives, so the real
  # target is chosen at install time:
  #
  #   disko-install --flake .#bifrost --disk main /dev/disk/by-id/<the-one-you-want>
  #
  # The --disk flag overwrites `device` here, which is why it is never
  # hardcoded to a real disk: a wrong value would erase the wrong drive.
  # scripts/install.sh walks through picking it.
  #
  # WHY by-id: kernel names (/dev/sda, /dev/nvme0n1) are handed out in probe
  # order and can swap between boots. by-id is tied to the hardware itself.

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/PLACEHOLDER-set-via-disko-install";
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
              "@snapshots" = {
                mountpoint = "/.snapshots";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
