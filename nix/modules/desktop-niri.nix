# Desktop session: Niri (from niri-flake) + a login manager.
# Niri config and the DankMaterialShell integration live in home-manager (modules/home.nix);
# Nix only installs the software here.
{ pkgs, ... }:
{
  # Niri compositor, enabled system-wide for the session / greetd (package from niri-flake).
  programs.niri.enable = true;

  # GPU / graphics stack (needed by any Wayland compositor).
  hardware.graphics.enable = true;

  # Log in through greetd into a Niri session.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
      user = "greeter";
    };
  };

  # Terminal only — DMS provides the bar, launcher, notifications, etc.
  environment.systemPackages = with pkgs; [ foot ];
}
