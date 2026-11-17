# home-manager wiring for the primary user (name comes from config.my.username).
# The DMS (Dux Modular Shell) integration lives here; the niri config itself is
# deployed by dotter (linux/niri/ in the repo).
{ config, lib, inputs, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };

  home-manager.users.${config.my.username} = {
    imports = [
      # niri home-manager module is added automatically by niri.nixosModules.niri.
      inputs.dux-shell.homeModules.dank-material-shell
      inputs.dux-shell.homeModules.niri
      ../home/packages.nix
    ];

    home.username = config.my.username;
    home.homeDirectory = "/home/${config.my.username}";
    home.stateVersion = "26.05";

    # config.kdl is hand-owned (dotter symlinks it, see linux/niri/ in the repo).
    # HM must not link it, or activation dies at checkLinkTargets and the whole
    # HM file layer silently stops applying.
    #
    # This force is also what makes `niri.enableKeybinds`/`enableSpawn` below
    # pointless: both work by adding entries to programs.niri.settings, which
    # niri-flake renders into exactly the file this disables. They are set false
    # to say so out loud rather than leaving dead options enabled — the binds and
    # the `spawn-at-startup "dms" "run"` line are written by hand in
    # linux/niri/config.kdl, which is the file that actually reaches disk.
    xdg.configFile."niri-config".enable = lib.mkForce false;

    # DMS (Dux Modular Shell) — Quickshell desktop shell over Niri.
    programs.dank-material-shell = {
      enable = true;

      niri = {
        enableKeybinds = false;
        enableSpawn = false;

        # THE load-bearing setting of this whole file, and the reason the
        # 2026-11-05 breakage is designed out rather than hoped away.
        #
        # With this true the module takes ownership of ~/.config/niri/config.kdl:
        # it rewrites that file into nothing but `include` lines and moves
        # niri-flake's own output to niri/hm.kdl. dotter owns config.kdl here, so
        # two writers would fight over one symlinked file.
        #
        # It also pulls in `dms/outputs.kdl` — `filesToInclude` defaults to
        # [alttab binds colors cursor layout outputs windowrules wpblur] — and
        # outputs is precisely the file that must never win against the `output`
        # blocks in linux/niri/config.kdl. Monitors stay niri's, by hand.
        #
        # Consequence accepted knowingly: no wallpaper-derived colours or layout
        # sync into niri's focus ring. That is how this machine ran before, and
        # the trade was deliberate then too.
        includes.enable = false;
      };

      # Deliberately NOT setting enableSystemMonitoring here, although Mod+M —
      # the process list, the one missing feature that drove the move back to
      # this shell — looks like it would need it. Traced instead of assumed: that
      # option is referenced in exactly one place in the whole module tree
      # (distro/nix/niri.nix, gating the Mod+M entry it would add to
      # programs.niri.settings), so with enableKeybinds off above it does
      # nothing at all. It installs no backend — there is no monitoring package
      # anywhere in distro/nix.
      #
      # Mod+M works regardless, and this is why: dux-gop is a Go LIBRARY
      # dependency of the shell's own core (core/go.mod,
      # github.com/duxlabs-dev/dux-gop), the server advertises "dgop" as an
      # unconditional capability (internal/server/server.go) and routes dgop.*
      # requests to itself (internal/server/router.go). No separate `dgop`
      # binary on PATH is involved. The bind lives in linux/niri/config.kdl.
    };
  };
}
