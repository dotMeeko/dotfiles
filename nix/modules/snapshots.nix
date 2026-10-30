# Btrfs snapshots via snapper (data/file recovery). System rollback itself is done
# by NixOS generations in the GRUB menu; snapper covers files in / and /home.
# Snapshots live in the @snapshots subvolume (/.snapshots) and under /home/.snapshots.
{ config, ... }:
let
  timeline = subvol: {
    SUBVOLUME = subvol;
    ALLOW_USERS = [ config.my.username ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = "5";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "2";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";
  };
in
{
  services.snapper.configs = {
    root = timeline "/";
    home = timeline "/home";
  };
}
