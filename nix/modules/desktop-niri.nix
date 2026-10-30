# Desktop session: Niri (from niri-flake) + a login manager.
# Niri config and the DankMaterialShell integration live in home-manager (modules/home.nix);
# Nix only installs the software here.
{ config, inputs, pkgs, ... }:
{
  # DankGreeter module is shipped by the dank-greeter flake, not nixpkgs.
  imports = [ inputs.dank-greeter.nixosModules.default ];

  # Niri compositor, enabled system-wide for the session / greetd (package from niri-flake).
  programs.niri.enable = true;

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

  # Terminal only — DMS provides the bar, launcher, notifications, etc.
  environment.systemPackages = with pkgs; [ ghostty ];
}
