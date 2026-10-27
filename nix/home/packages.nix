# home-manager profile. Per Architecture — ONLY `home.packages` (packages),
# no `programs.*`, so Nix never generates configs and never fights chezmoi.
{ pkgs, ... }:
{
  home.username = "meeko";
  home.homeDirectory = "/home/meeko";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    git
    vim
  ];
}
