# Docker for development. A system module rather than a home/packages.nix entry,
# because what is needed here is a daemon plus a group — neither can come from
# home.packages.
{ config, ... }:
{
  virtualisation.docker.enable = true;

  # /var/lib/docker gets its own Btrfs subvolume. `v` in tmpfiles means "subvolume
  # if the filesystem supports it, directory otherwise", so this is a no-op on a
  # non-Btrfs machine.
  #
  # Why it matters here: / is the `@` subvolume and snapper takes timeline
  # snapshots of it (modules/snapshots.nix — 5 hourly, 7 daily, 2 weekly). Image
  # layers are gigabytes and churn constantly, and every pull or prune would be
  # pinned in those snapshots until they expire. Btrfs snapshots are not
  # recursive, so a nested subvolume is simply skipped — images stay out of
  # snapshots entirely. It also happens to be what Docker's own btrfs storage
  # driver expects of its data root.
  systemd.tmpfiles.rules = [ "v /var/lib/docker 0710 root root -" ];

  # Membership in `docker` is root-equivalent: the socket takes requests to mount
  # any host path into a privileged container. Accepted deliberately — the
  # alternative, virtualisation.docker.rootless.enable, cannot bind ports below
  # 1024 and trips over bind mounts, which is the wrong trade for a single-user
  # workstation.
  users.users.${config.my.username}.extraGroups = [ "docker" ];

  # NOT HERE, on purpose:
  #
  # - pkgs.docker-compose. `pkgs.docker` already builds with composeSupport and
  #   buildxSupport on, and the CLI has both plugin directories baked into it
  #   (checked: it carries the docker-compose and docker-buildx store paths), so
  #   `docker compose` and `docker buildx` work with nothing added. Installing the
  #   package too would only put a second, unrelated `docker-compose` on PATH.
  # - virtualisation.docker.autoPrune. It runs `docker system prune -f`, which
  #   deletes dangling images and the whole build cache on a timer. Surprise
  #   deletions are worse than a full disk that says so.
  # - hardware.nvidia-container-toolkit.enable. Needed only to pass this box's GPU
  #   into containers; enable it then, not preemptively (and note the old
  #   virtualisation.docker.enableNvidia is deprecated in favour of it).
}
