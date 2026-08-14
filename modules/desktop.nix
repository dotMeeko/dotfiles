{ pkgs, ... }:

{
  # --- Niri ------------------------------------------------------------------
  # This enable comes from niri-flake (see flake.nix), which disables the
  # nixpkgs module to avoid a conflict. It sets up xdg-portal, gnome-keyring,
  # polkit and the session entry itself. The actual configuration — keybindings,
  # layout, input — lives in home/niri.nix.
  programs.niri.enable = true;

  # --- DankMaterialShell (DMS) -----------------------------------------------
  # Quickshell-based shell: bar, launcher, notifications, lock screen.
  # The flake input tracks the stable branch, not master.
  programs.dank-material-shell = {
    enable = true;
    # Start together with the graphical session.
    systemd.enable = true;
    # Everything else (system monitoring, VPN widget, dynamic theming,
    # audio wavelength, calendar) is enabled by the module's own defaults.
  };

  # DMS pulls in polkit, power-profiles-daemon, accounts-daemon and geoclue2
  # itself, but not Bluetooth or UPower — without these the matching widgets
  # in the bar stay empty. NetworkManager is already on in configuration.nix.
  hardware.bluetooth.enable = true;
  services.upower.enable = true;

  # --- Display manager -------------------------------------------------------
  # greetd + tuigreet: lightweight, no heavy DE. Logs straight into niri.
  services.greetd = {
    enable = true;
    # Creates /var/cache/tuigreet, otherwise the greeter complains about it.
    useTextGreeter = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
      user = "greeter";
    };
  };

  # --- Audio -----------------------------------------------------------------
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # --- Fonts -----------------------------------------------------------------
  # DMS is built around Material Design: without material-symbols the icons
  # in the bar render as empty boxes.
  fonts.packages = with pkgs; [
    material-symbols
    roboto
    nerd-fonts.jetbrains-mono
    inter
    noto-fonts
    noto-fonts-emoji
  ];

  # --- Minimal set for a usable Wayland desktop ------------------------------
  # The terminal and CLI tools are installed per-user via home-manager, so
  # they are configured and installed in one place. What stays here is what the
  # system genuinely owns.
  environment.systemPackages = with pkgs; [
    xwayland-satellite # X11 apps inside niri
    wl-clipboard
    brightnessctl
    pavucontrol
  ];
  # No need to enable gnome-keyring or xdg-portal — the niri module does it.
}
