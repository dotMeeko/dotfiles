# Desktop session: Niri (from niri-flake) + a login manager.
# The niri config itself is deployed by dotter (linux/niri/ in the repo), and the
# shell on top of it is Noctalia (installed in home/packages.nix);
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

  # greetd's whole session command, replaced wholesale. Three jobs, each
  # load-bearing:
  #
  # 1. XDG_DATA_DIRS. Without it the greeter offers no sessions to log into at
  #    all: NixOS keeps session .desktop files in a generated aggregate that is
  #    not part of the system profile, so the greeter cannot find them the usual
  #    way (nixpkgs#582861). Upstream's module sets this in the command it
  #    builds — overriding that command means repeating it here.
  #
  # 2. waynergy, so the Mac's keyboard can type the password. This cannot reuse
  #    the dms-greeter trick of an include in the greeter's compositor config:
  #    noctalia-greeter runs its OWN wlroots compositor and ignores whatever
  #    command follows `--` (verified — it always maps its own greeter surface),
  #    so there is no hook to use. Instead we wait for that compositor's Wayland
  #    socket and attach to it.
  #
  #    That waynergy works against that compositor at all was verified before
  #    committing to this design, not assumed: with WAYLAND_DISPLAY pointed at a
  #    headless instance of it, waynergy 0.0.17 logged "Geometry updated:
  #    1280x720" and "Using uinput".
  #
  # 3. Lifetime. When the greeter session ends, waynergy goes with it; a leftover
  #    instance would fight the user's own over the screen name, which the server
  #    answers with EBSY.
  #
  # -n disables clipboard sync: wl-copy needs the data-control protocol, which
  # this compositor does not offer (it fails loudly in the log), and pulling the
  # Mac's clipboard into a login screen is pointless anyway.
  greeterSessionCommand = pkgs.writeShellScript "noctalia-greeter-session-with-waynergy" ''
    set -u

    # Greeter and compositor logs. Their session script parks stdout/stderr on
    # /dev/null by default so wlroots does not paint over the VT, which means a
    # failing greeter leaves NOTHING in the journal — that is how the first
    # version of this script failed invisibly. A file keeps the logs without
    # touching the VT; /var/lib/noctalia-greeter is created greeter-owned by the
    # module's tmpfiles rules.
    export NOCTALIA_GREETER_LOG=/var/lib/noctalia-greeter/session.log

    ${pkgs.coreutils}/bin/env \
      XDG_DATA_DIRS="${config.services.displayManager.sessionData.desktops}/share" \
      ${config.services.displayManager.noctalia-greeter.package}/bin/noctalia-greeter-session -- &
    session=$!

    # Where the compositor's Wayland socket actually turns up.
    #
    # NOT $XDG_RUNTIME_DIR, and this is the whole bug of the first attempt:
    # noctalia-greeter-session OVERWRITES that variable with
    # /tmp/noctalia-runtime-$(id -u) before starting the compositor, and does not
    # use PAM's. On this machine PAM does not even create /run/user/999, so the
    # original loop watched a directory that never existed, found nothing for ten
    # seconds and gave up without a word.
    #
    # PAM's dir is still checked second, in case upstream ever goes back to it.
    waynergy_runtime="/tmp/noctalia-runtime-$(${pkgs.coreutils}/bin/id -u)"

    # Deliberately NOT `exec`, and every socket is tried on every pass. A socket
    # file existing says nothing about anything listening on it: /tmp survives
    # reboots on this machine (cleanOnBoot is off and /tmp is not a tmpfs), so a
    # dead wayland-0 from the previous boot sits there, wlroots skips it because
    # its lock is stale and listens on wayland-1 instead — and a loop that globbed
    # in alphabetical order and exec'd once grabbed the corpse and died with
    # "Could not connect to display". Falling through on failure makes the next
    # candidate, and the next pass, fix it by themselves.
    (
      attempt=0
      while [ "$attempt" -lt 60 ]; do
        attempt=$((attempt + 1))
        for sock in "$waynergy_runtime"/wayland-* "''${XDG_RUNTIME_DIR:-/nonexistent}"/wayland-*; do
          case "$sock" in *.lock | *'*') continue ;; esac
          [ -S "$sock" ] || continue
          # systemd-cat so this lands in the journal under a name worth grepping:
          # journalctl -b -t greeter-waynergy
          XDG_RUNTIME_DIR="''${sock%/*}" \
          WAYLAND_DISPLAY="''${sock##*/}" \
          WAYNERGY_CONF_PATH=${greeterWaynergyConf} \
            ${pkgs.systemd}/bin/systemd-cat -t greeter-waynergy \
              ${pkgs.waynergy}/bin/waynergy -n
          # Returned, so either that socket was dead or the greeter just ended.
          # Either way: rescan.
        done
        ${pkgs.coreutils}/bin/sleep 1
      done
      echo "greeter-waynergy: no usable Wayland socket after 60 attempts" \
        | ${pkgs.systemd}/bin/systemd-cat -t greeter-waynergy -p warning
    ) &
    waynergy=$!

    wait "$session"
    kill "$waynergy" 2>/dev/null || :
  '';

in
{
  # Noctalia Greeter module is shipped by its own flake — see nix/flake.nix for
  # why it cannot come from the pinned nixpkgs.
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  # Niri compositor, enabled system-wide for the session / greetd.
  programs.niri.enable = true;

  # Use nixpkgs' niri (26.04) instead of niri-flake's niri-stable (25.08).
  #
  # The original reason was DankMaterialShell writing `include` lines into
  # config.kdl, which 25.08 cannot parse at all ("unexpected node `include`") —
  # that took the whole session down. Noctalia never touches the niri config, so
  # that particular trap is gone, but the version override stays: the config here
  # uses `debug { honor-xdg-activation-with-invalid-serial }`, which Noctalia needs
  # for notification actions and which was checked against 26.04.
  #
  # Note it does NOT fix compositor keybinds from virtual-keyboard input — that
  # fix merged upstream 2026-10-13, after 26.04, which is why keyboard sharing
  # goes through uinput instead (see below).
  programs.niri.package = pkgs.niri;

  # GPU / graphics stack (needed by any Wayland compositor).
  hardware.graphics.enable = true;

  # Log in through Noctalia Greeter — greetd-based, and it brings its own small
  # wlroots compositor rather than running niri like dms-greeter did.
  services.displayManager.noctalia-greeter = {
    enable = true;

    # Module from their flake, package from unstable. The flake's own package
    # would be built from source here, while unstable ships 1.7.0 prebuilt in the
    # binary cache; the module only wires greetd, tmpfiles and polkit, so it does
    # not care which build it points at.
    package = pkgs.unstable.noctalia-greeter;

    # Lets the session push its theme to the login screen without an
    # authentication prompt — the rough equivalent of dms-greeter's configHome.
    passwordless-sync-users = [ config.my.username ];

    settings = {
      # Match the cursor the session uses (see the cursor block in the niri config).
      cursor = {
        theme = "Adwaita";
        size = 24;
      };

      # Same layouts as the session, but deliberately NOT the same toggle.
      # us first so the prompt always starts on Latin — a login screen is the
      # worst place to be stuck in an invisible layout group — and Alt+Shift
      # rather than Super+Space because the greeter shows no layout indicator,
      # so the switch should be one you press on purpose. Over Deskflow this
      # arrives as Control+Shift, since the waynergy raw-keymap maps the Mac's
      # Control onto Alt.
      keyboard = {
        layout = "us,ru";
        options = "grp:alt_shift_toggle";
      };

      # Display settings for the login screen. This is what replaces the niri
      # `output` block the dms-greeter setup used: noctalia-greeter's own
      # compositor reads these from greeter.toml instead.
      output = {
        # Per-output form because the two monitors differ: DP-3 is a 120 Hz
        # panel while the 4K DP-2 is 60 Hz. Nominal values match fractional
        # modes within 1 Hz, so 60 picks up DP-2's actual 59.997.
        refresh_rate = "DP-3:120; DP-2:60";

        # Same scales as the session — at 1:1 the prompt is unreadable on 4K.
        scales = "DP-3:1; DP-2:1.25";

        # No `name` on purpose: pinning the greeter to one connector hides it on
        # the other monitor, while omitting it mirrors the prompt on every
        # output. No `width`/`height` either — that pair is global, and these two
        # panels have different resolutions, so a single size would be wrong for
        # one of them. Each output keeps its own preferred mode and only the
        # refresh rate is forced.
      };
    };
  };

  # The command the module builds is replaced here, because the remote keyboard
  # has to be started inside the greeter session — see greeterSessionCommand
  # above for the three things that script has to do.
  services.greetd.settings.default_session.command = lib.mkForce "${greeterSessionCommand}";

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
  # The same waynergy+uinput path as the session, but running inside the greeter
  # session — see greeterSessionCommand above for how it gets in there. Not a
  # shortcut either: input on a Wayland login screen CANNOT go through the
  # RemoteDesktop portal, because the portal needs a user session and a human to
  # approve the capture, and a greeter has neither. Symless documents the
  # consequence for their own product — Synergy 3's "Run on the login screen" is
  # greyed out on Linux, and Synergy 1's pre-login mode needs X11 plus GDM.
  # Kernel-level injection is the only thing that works here, which is also why
  # this cannot be swapped for a portal client later.
  #
  # LOST in the move from dms-greeter, and worth knowing: the login screen's
  # refresh rate is no longer ours to set. dms-greeter ran niri, so an `output`
  # block could pin DP-3 to 120 Hz; noctalia-greeter runs its own compositor and
  # takes its display settings from greeter.toml instead. Its settings do have an
  # `output` section — mapping that out is a separate job.

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
  # Guarded with `|| :` as a whole, exactly like the dms-greeter lines above it:
  # NixOS runs preStart under `set -e`, so an unguarded failure here would stop
  # greetd from starting at all — a black screen instead of a login prompt.
  # Remote input is a convenience and must never be able to take the greeter down
  # with it.
  systemd.services.greetd.preStart = lib.mkAfter ''
    {
      # The greeter's compositor puts its Wayland socket in
      # /tmp/noctalia-runtime-<uid> (its session script forces XDG_RUNTIME_DIR
      # there), and /tmp is neither a tmpfs nor cleaned on boot here — so last
      # boot's dead socket and its stale lock are still sitting in it. Clearing it
      # as root means every greetd start gets exactly one, live socket.
      ${pkgs.coreutils}/bin/rm -rf "/tmp/noctalia-runtime-$(${pkgs.coreutils}/bin/id -u ${greeterUser})"

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
