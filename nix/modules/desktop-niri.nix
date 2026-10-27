# Desktop: Niri Wayland compositor + a login manager + minimal Wayland packages.
# Nix installs the software; the Niri config itself is a dotfile managed by chezmoi.
# Niri comes from the unstable overlay (pkgs.unstable) to stay fresh.
{ pkgs, ... }:
{
  # GPU / graphics stack (needed by any Wayland compositor).
  hardware.graphics.enable = true;

  programs.niri = {
    enable = true;
    package = pkgs.unstable.niri;
  };

  # Log in through greetd into a Niri session.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
      user = "greeter";
    };
  };

  # Minimal Wayland desktop tools (install only; their configs come from chezmoi).
  environment.systemPackages = with pkgs; [
    foot # terminal
    fuzzel # application launcher
    waybar # status bar
  ];
}
