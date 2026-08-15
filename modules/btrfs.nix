{ ... }:

let
  user = import ../user.nix;
in
{
  # --- Btrfs maintenance -----------------------------------------------------
  #
  # The subvolume layout and every mount live in modules/disko.nix — disko
  # generates the fileSystems entries from the same declaration it partitions
  # with, so they cannot drift apart. What is left here is upkeep.
  #
  # The layout, for reference:
  #   @          -> /            system state
  #   @home      -> /home        YOUR files — never rolled back with the system
  #   @nix       -> /nix         the store
  #   @log       -> /var/log     logs survive a rollback, which is the point:
  #                              you need the logs of whatever broke
  #   @home-snapshots -> /home/.snapshots
  #                              snapper requires a subvolume literally named
  #                              .snapshots inside the one it manages. It is a
  #                              separate subvolume, so rolling @home back does
  #                              not take the snapshots with it
  #
  # HOW A ROLLBACK WORKS HERE:
  # The system itself rolls back through the NixOS generation menu in GRUB —
  # pick an older entry and the whole config comes back while /home stays put.
  # The snapshots below cover the other direction: recovering personal files.

  # --- Snapshots of personal data -------------------------------------------
  # /home only. The system is already covered by generations, so snapshotting
  # the root subvolume would mostly duplicate that.
  #
  # Browse:  snapper -c home list
  # Restore: snapper -c home undochange <n1>..<n2> <path>
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs.home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = [ user.username ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 6;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 2;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  # --- Integrity -------------------------------------------------------------
  # Btrfs checksums everything; scrubbing verifies it and catches bit rot early.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
