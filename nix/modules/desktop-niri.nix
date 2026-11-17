# Desktop session: Niri (from niri-flake) + a login manager.
# The niri config itself is deployed by dotter (linux/niri/ in the repo) and the
# DMS integration lives in home-manager (modules/home.nix); Nix only installs
# the software here.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # The greeter runs as whatever user greetd starts the default session as. Read
  # it from the same place the dms-greeter module reads it, so the two can never
  # disagree about who needs the uinput group and who owns the config copy.
  greeterUser = config.services.greetd.settings.default_session.user;
  greeterGroup =
    if config.users.users.${greeterUser}.group != "" then
      config.users.users.${greeterUser}.group
    else
      "greeter";

  # The greeter cannot read /home/<user> (0700), so greetd copies the client
  # config here as root before starting — see systemd.services.greetd.preStart.
  greeterWaynergyConf = "/var/lib/greetd-waynergy";
  userWaynergyConf = "/home/${config.my.username}/.config/waynergy";

  # No restart loop around waynergy, on purpose. It already retries the
  # connection itself ("trying to reconnect in a second") when the Mac is asleep
  # or Deskflow is not up yet, which is the only failure worth surviving here. A
  # loop could outlive the greeter session and then fight the user's own instance
  # over the screen name, which the server answers with EBSY.
  #
  # -n disables clipboard sync: wl-copy is not in the greeter's PATH, and pulling
  # the Mac's clipboard into a login screen is pointless at best.
  greeterWaynergy = pkgs.writeShellScript "waynergy-greeter" ''
    export WAYNERGY_CONF_PATH=${greeterWaynergyConf}
    exec ${pkgs.waynergy}/bin/waynergy -n
  '';
in
{
  # Dux Greeter module comes from its own flake — the shell flake's
  # `nixosModules.greeter` is now a stub that only points here. Options still
  # live under programs.dms-greeter, not services.displayManager.*.
  imports = [ inputs.dux-greeter.nixosModules.default ];

  # Niri compositor, enabled system-wide for the session / greetd.
  programs.niri.enable = true;

  # Use nixpkgs' niri (26.04) instead of niri-flake's niri-stable (25.08).
  #
  # The `include` directive landed in niri 25.11 and `optional=true` in 26.04.
  # This config grants DMS no includes at all (see linux/niri/config.kdl), but
  # the shell can still append one by itself the first time its settings UI
  # touches something it wants to own — and on 25.08 a single `include` line
  # makes the WHOLE config fail to parse, which kills the session and bounces
  # you back to a grey login screen. Verified both ways: 26.04 accepts the file,
  # 25.08 rejects it with "unexpected node `include`". Keeping 26.04 turns that
  # from a dead session into a diff in the repo.
  #
  # Note it does NOT fix compositor keybinds from virtual-keyboard input — that
  # fix merged upstream 2026-10-13, after 26.04, which is why keyboard sharing
  # goes through uinput instead (see below).
  programs.niri.package = pkgs.niri;

  # GPU / graphics stack (needed by any Wayland compositor).
  hardware.graphics.enable = true;

  # Log in through Dux Greeter — greetd-based, DMS-styled. The module enables
  # greetd itself and launches the greeter inside a Niri session, which is what
  # makes the niri_overrides.kdl hook below possible at all.
  #
  # configHome makes it copy the user's DMS theme/wallpaper. The module turns
  # that into a configFiles list covering both the old DankMaterialShell paths
  # and the current ~/.config/dms ones, so the rename needs nothing from us.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${config.my.username}";
  };

  # Kernel-level virtual input, for waynergy's uinput backend — how this machine
  # receives the Mac's keyboard and mouse (server there is Deskflow).
  #
  # uinput is not a shortcut, it is the only route that works here. niri ships no
  # RemoteDesktop portal (niri-wm/niri#1966 is open), and input injected through
  # zwp_virtual_keyboard_v1 does not trigger niri's own keybinds until the fix
  # merged upstream 2026-10-13 reaches a release — 26.04 predates it. Writing to
  # /dev/uinput makes the kernel create a real input device, so niri handles it
  # like any keyboard, keybinds included.
  #
  # Trade-off: kernel input bypasses the compositor's access control, so a lock
  # screen is no longer a hard barrier while a session is active.
  #
  # The user also needs to be in the "uinput" group — see modules/base.nix.
  # Client config and the Apple keycode table are deployed by dotter to
  # ~/.config/waynergy/. It runs as a user service bound to graphical-session
  # (linux/systemd/waynergy.service in the repo) and, since the block below, in
  # the greeter too — so the Mac's keyboard reaches the password prompt.
  hardware.uinput.enable = true;

  # ── Keyboard and mouse BEFORE login ───────────────────────────────────────
  #
  # The same waynergy+uinput path as the session, but running inside the
  # greeter's own niri. Not a shortcut either: input on a Wayland login screen
  # CANNOT go through the RemoteDesktop portal, because the portal needs a user
  # session and a human to approve the capture, and a greeter has neither.
  # Symless documents the consequence for their own product — Synergy 3's "Run
  # on the login screen" is greyed out on Linux, and Synergy 1's pre-login mode
  # needs X11 plus GDM. Kernel-level injection is the only thing that works
  # here, which is also why this cannot be swapped for a portal client later.

  # dms-greeter appends `include "/etc/greetd/niri_overrides.kdl"` to the niri
  # config it generates for the greeter, but only when that file exists
  # (core/internal/launcher/compositor.go — checked in dux-greeter 2.1.0, where
  # the hook survived the rename). Using its own hook beats copying the embedded
  # config just to add one line: the greeter keeps following upstream when the
  # flake updates.
  #
  # This hook is also why the greeter can set its own refresh rate here, which a
  # greeter running its own non-niri compositor cannot.
  environment.etc."greetd/niri_overrides.kdl".text = ''
    spawn-at-startup "${greeterWaynergy}"

    // Refresh rate at the login screen. Without this niri takes the mode the
    // display calls preferred in its EDID, which on DP-3 is 60 Hz even though the
    // panel does 120 — the greeter would run at half the session's rate.
    //
    // Deliberately NO `position` here, and the session agrees (see the output
    // blocks in linux/niri/config.kdl). Pinning positions is what put a lone
    // connected monitor at its dual-layout slot — DP-3 at x=3072, right of the
    // 4K — leaving a 3072 px phantom gap. That gap is what made the remote mouse
    // crawl: waynergy measures the screen as the bounding box FROM ZERO, so it
    // reported 4992 px wide for a 1920 px screen. niri's own left-to-right
    // auto-placement never leaves gaps, which is exactly what a greeter wants.
    //
    // Blocks for outputs that are not connected are ignored, so both can be
    // listed unconditionally and a monitor can be plugged in or left off freely.
    output "DP-3" {
        mode "1920x1080@120.000"
    }

    output "DP-2" {
        // Matches the session (linux/niri/config.kdl). 59.997 stood here until
        // 2026-11-17 and was wrong for the same reason it was wrong there: it is
        // only the panel's `preferred` mode, while the thing actually does 144.
        mode "3840x2160@143.963"
        // 4K at 1:1 would render the login prompt unreadably small. Matches the
        // scale the session uses for this monitor.
        scale 1.25
    }
  '';

  # /dev/uinput is 0660 root:uinput (hardware.uinput above creates the group and
  # the udev rule), so the greeter has to be in that group as well — the login
  # user already is, via modules/base.nix.
  users.users.${greeterUser}.extraGroups = [ "uinput" ];

  # ONE source of truth for the client config: the user's dotter-deployed
  # ~/.config/waynergy, copied in as root when greetd starts. Two consequences
  # are the whole reason for doing it this way — /home/<user> can stay 0700, and
  # the Mac's address never has to be committed to this repo (it lives in
  # .dotter/local.toml, which is gitignored). The whole directory, because
  # waynergy merges config.ini with every file in config.ini.d/ (src/config.c)
  # and that is where the Apple keycode table lives.
  #
  # Guarded with `|| :` as a whole: NixOS runs preStart under `set -e`, so an
  # unguarded failure here would stop greetd from starting at all — a black
  # screen instead of a login prompt. Remote input is a convenience and must
  # never be able to take the greeter down with it.
  systemd.services.greetd.preStart = lib.mkAfter ''
    {
      ${pkgs.coreutils}/bin/rm -rf ${greeterWaynergyConf}
      ${pkgs.coreutils}/bin/install -d -m 0750 -o ${greeterUser} -g ${greeterGroup} ${greeterWaynergyConf}
      if [ -d ${userWaynergyConf} ]; then
        # -L, and it is load-bearing. dotter deploys the Apple keycode table as a
        # SYMLINK into the repo under /home/<user>, which the greeter cannot read
        # at all (0700). A plain `cp -a` preserves that symlink, so the greeter got
        # a dangling link, loaded no raw-keymap, and every key arrived shifted —
        # Backspace typed "z". Dereferencing here turns it into a real file while
        # still running as root, which is the only context that can read through it.
        # This did not happen under chezmoi, which deployed plain files.
        ${pkgs.coreutils}/bin/cp -aL ${userWaynergyConf}/. ${greeterWaynergyConf}/
        ${pkgs.coreutils}/bin/chown -R ${greeterUser}:${greeterGroup} ${greeterWaynergyConf}
      fi
    } || :
  '';

  # Terminal only — DMS provides the bar, launcher, notifications, etc.
  environment.systemPackages = with pkgs; [ ghostty ];
}
