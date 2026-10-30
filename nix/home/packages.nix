# home-manager profile. Per Architecture — ONLY `home.packages` (packages),
# no `programs.*`, so Nix never generates configs and never fights chezmoi.
{ pkgs, inputs, ... }:
{
  home.packages = [
    pkgs.git
    pkgs.vim

    # Standard GTK file manager.
    pkgs.nautilus

    # Claude Code — from unstable (frequent releases; unfree allowed in the unstable overlay).
    pkgs.unstable.claude-code

    # Zen browser — package from the flake (no programs.* so chezmoi keeps owning the config).
    inputs.zen-browser.packages.${pkgs.system}.default
  ];
}
