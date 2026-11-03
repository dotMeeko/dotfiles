# home-manager profile. Per Architecture — ONLY `home.packages` (packages),
# no `programs.*`, so Nix never generates configs and never fights chezmoi.
{ pkgs, inputs, ... }:
{
  home.packages = [
    pkgs.git
    pkgs.vim

    # Standard GTK file manager.
    pkgs.nautilus

    # chezmoi — owns all dotfiles per the README; was never actually installed,
    # so the whole home/ layer had never been deployed.
    pkgs.chezmoi

    # X11 apps under niri. niri 25.08 spawns this from PATH by itself
    # (log showed "error spawning xwayland-satellite, disabling integration").
    pkgs.xwayland-satellite

    # Real cursor theme — config.kdl referenced a non-existent "default".
    pkgs.adwaita-icon-theme

    # Claude Code — from stable 26.05 (unfree, allowed via allowUnfreePredicate).
    pkgs.claude-code

    # Zen browser — "beta" is Zen's public release channel (NOT a pre-release; twilight is the
    # nightly). Package only (no programs.*), so chezmoi keeps owning the config.
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
  ];
}
