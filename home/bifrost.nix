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

  # home/niri.nix writes screenshots here; make sure the directory exists.
  home.file."Pictures/screenshots/.keep".text = "";

  # Linux-only extras. The shared set lives in common.nix.
  home.packages = with pkgs; [
    unzip
  ];
}
