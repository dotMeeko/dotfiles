# Desktop session: Niri (from niri-flake) + a login manager.
# Niri config and the DankMaterialShell integration live in home-manager (modules/home.nix);
# Nix only installs the software here.
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
  # DankGreeter module is shipped by the dank-greeter flake, not nixpkgs.
  imports = [ inputs.dank-greeter.nixosModules.default ];

  # Niri compositor, enabled system-wide for the session / greetd.
  programs.niri.enable = true;

  # Use nixpkgs' niri (26.04) instead of niri-flake's niri-stable (25.08).
  #
  # The `include` directive landed in niri 25.11 and `optional=true` in 26.04.
  # DankMaterialShell writes `include "dms/outputs.kdl"` into config.kdl whenever
  # its settings UI touches outputs — on 25.08 that one line makes the WHOLE config
  # fail to parse, so the session dies and greetd bounces you back to a grey login
  # screen. Verified: 26.04 accepts that exact file, 25.08 rejects it with
  # "unexpected node `include`".
  #
  # This also makes the ~/.config/niri/dms/*.kdl files DMS generates actually
  # usable rather than inert. Note it does NOT fix compositor keybinds from
  # virtual-keyboard input — that fix merged upstream 2026-10-13, after 26.04,
  # which is why keyboard sharing goes through uinput instead (see below).
  programs.niri.package = pkgs.niri;

  # GPU / graphics stack (needed by any Wayland compositor).
  hardware.graphics.enable = true;

  # Log in through DankGreeter — greetd-based, DMS-styled. The module (from the dank-greeter
  # flake) enables greetd itself and launches the greeter in a Niri session.
  # Options live under programs.dms-greeter (NOT services.displayManager.* — that was the
  # old nixpkgs module). configHome makes it copy the user's DMS theme/wallpaper.
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
  # Client config and the Apple keycode table are deployed by chezmoi to
  # ~/.config/waynergy/. It runs as a user service bound to graphical-session
  # (home/dot_config/systemd/user/waynergy.service) and, since the block below,
  # in the greeter too — so the Mac's keyboard reaches the password prompt.
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
  # (core/internal/launcher/compositor.go, buildNiriPlan). Using its own hook
  # beats copying the embedded config just to add one line: the greeter keeps
  # following upstream when the flake updates.
  environment.etc."greetd/niri_overrides.kdl".text = ''
    spawn-at-startup "${greeterWaynergy}"

    // Refresh rate at the login screen. Without this niri takes the mode the
    // display calls preferred in its EDID, which on DP-3 is 60 Hz even though the
    // panel does 120 — the greeter would run at half the session's rate.
    //
    // Deliberately NO `position` here. The session takes positions from DMS's
    // per-monitor-set profiles, and repeating them would put a lone connected
    // monitor at its dual-layout slot (DP-3 at x=3072, right of the 4K), leaving a
    // 3072 px phantom gap. That gap is what made the remote mouse crawl: waynergy
    // measures the screen as the bounding box FROM ZERO, so it reported 4992 px
    // wide for a 1920 px screen. niri's own left-to-right auto-placement never
    // leaves gaps, which is exactly what a greeter wants.
    //
    // Blocks for outputs that are not connected are ignored, so both can be
    // listed unconditionally and a monitor can be plugged in or left off freely.
    output "DP-3" {
        mode "1920x1080@120.000"
    }

    output "DP-2" {
        mode "3840x2160@59.997"
        // 4K at 1:1 would render the login prompt unreadably small. Matches the
        // scale DMS uses for this monitor in the session.
        scale 1.25
    }
  '';

  # /dev/uinput is 0660 root:uinput (hardware.uinput above creates the group and
  # the udev rule), so the greeter has to be in that group as well — the login
  # user already is, via modules/base.nix.
  users.users.${greeterUser}.extraGroups = [ "uinput" ];

  # ONE source of truth for the client config: the user's chezmoi-deployed
  # ~/.config/waynergy, copied in as root when greetd starts. Two consequences
  # are the whole reason for doing it this way — /home/<user> can stay 0700, and
  # the Mac's address never has to be committed to this repo (it lives in
  # chezmoi.toml under [data]). The whole directory, because waynergy merges
  # config.ini with every file in config.ini.d/ (src/config.c) and that is where
  # the Apple keycode table lives.
  #
  # Guarded with `|| :` as a whole, exactly like the dms-greeter lines above it:
  # NixOS runs preStart under `set -e`, so an unguarded failure here would stop
  # greetd from starting at all — a black screen instead of a login prompt.
  # Remote input is a convenience and must never be able to take the greeter down
  # with it.
  systemd.services.greetd.preStart = lib.mkAfter ''
    {
      ${pkgs.coreutils}/bin/rm -rf ${greeterWaynergyConf}
      ${pkgs.coreutils}/bin/install -d -m 0750 -o ${greeterUser} -g ${greeterGroup} ${greeterWaynergyConf}
      if [ -d ${userWaynergyConf} ]; then
        ${pkgs.coreutils}/bin/cp -a ${userWaynergyConf}/. ${greeterWaynergyConf}/
        ${pkgs.coreutils}/bin/chown -R ${greeterUser}:${greeterGroup} ${greeterWaynergyConf}
      fi
    } || :
  '';

  # Terminal only — DMS provides the bar, launcher, notifications, etc.
  environment.systemPackages = with pkgs; [ ghostty ];
}
