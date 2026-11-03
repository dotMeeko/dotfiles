# Desktop session: Niri (from niri-flake) + a login manager.
# Niri config and the DankMaterialShell integration live in home-manager (modules/home.nix);
# Nix only installs the software here.
{
  config,
  inputs,
  pkgs,
  ...
}:
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
  # ~/.config/waynergy/; it runs on demand via the "Keyboard Sharing" toggle,
  # not at login.
  hardware.uinput.enable = true;

  # Terminal only — DMS provides the bar, launcher, notifications, etc.
  environment.systemPackages = with pkgs; [ ghostty ];
}
