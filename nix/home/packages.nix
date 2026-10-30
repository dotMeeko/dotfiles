# home-manager profile. Per Architecture — ONLY `home.packages` (packages),
# no `programs.*`, so Nix never generates configs and never fights chezmoi.
{ pkgs, inputs, ... }:
{
  home.packages = [
    pkgs.git
    pkgs.vim

    # Standard GTK file manager.
    pkgs.nautilus

    # Claude Code — from stable 26.05 (unfree, allowed via allowUnfreePredicate).
    pkgs.claude-code

    # Zen browser — "beta" is Zen's public release channel (NOT a pre-release; twilight is the
    # nightly). Package only (no programs.*), so chezmoi keeps owning the config.
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
  ];
}
