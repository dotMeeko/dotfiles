{ pkgs, ... }:

let
  user = import ../user.nix;
in
{
  # bifrost — the Linux/NixOS side of the home config.

  imports = [
    ./common.nix
    ./starship.nix
    ./ghostty.nix
    ./niri.nix
  ];

  home.username = user.username;
  home.homeDirectory = "/home/${user.username}";

  # Same rule as system.stateVersion: set once, do not bump it later.
  home.stateVersion = "26.05";

  # --- Shell aliases specific to this machine --------------------------------
  programs.zsh.shellAliases = {
    # Rebuild and switch straight from the repo.
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos-cfg#bifrost";
    # Roll the system back one generation.
    rollback = "sudo nixos-rebuild switch --rollback";
    # What is bootable right now.
    generations = "nixos-rebuild list-generations";
    # Browse and restore /home snapshots.
    snaps = "snapper -c home list";
  };

  # --- XDG user directories --------------------------------------------------
  # Create the standard set (Documents, Downloads, Pictures, Music, Videos,
  # Desktop, Public, Templates) and write ~/.config/user-dirs.dirs so apps that
  # ask "where do downloads go" get a real answer. English names, to match the
  # rest of the system.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # home/niri.nix writes screenshots here; make sure the directory exists.
  # (xdg.userDirs makes ~/Pictures; this adds the subdirectory under it.)
  home.file."Pictures/screenshots/.keep".text = "";

  # --- Zen browser -----------------------------------------------------------
  # Packaged by the zen-browser flake (see flake.nix); the home module comes in
  # through home-manager.sharedModules there.
  programs.zen-browser = {
    enable = true;
    # Register it as the handler for http(s) and .html.
    setAsDefaultBrowser = true;
  };

  # --- Zed editor ------------------------------------------------------------
  # zed-editor is in nixpkgs; this module manages ~/.config/zed declaratively.
  # Add extensions/keymaps/settings here as they grow.
  programs.zed-editor = {
    enable = true;
    userSettings = {
      telemetry = {
        metrics = false;
        diagnostics = false;
      };
    };
  };

  # Linux-only extras. The shared set lives in common.nix.
  home.packages = with pkgs; [
    unzip
  ];
}
