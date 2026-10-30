# home-manager profile. Per Architecture — ONLY `home.packages` (packages),
# no `programs.*`, so Nix never generates configs and never fights chezmoi.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    vim
  ];
}
