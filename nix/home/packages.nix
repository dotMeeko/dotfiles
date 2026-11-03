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

    # KVM: Synergy-1-protocol client with a uinput backend — the only Linux client
    # that injects below Wayland, so niri's own keybinds work from remote input.
    # Pairs with Deskflow (or Synergy 1) as the server; Synergy 3 speaks only to
    # Synergy 3 and cannot be used here.
    pkgs.waynergy

    # waynergy shells out to wl-copy/wl-paste for clipboard sync; without it it
    # logs "wl-clipboard not found, no clipboard synchronization support".
    pkgs.wl-clipboard

    # Claude Code — from stable 26.05 (unfree, allowed via allowUnfreePredicate).
    pkgs.claude-code

    # Needed on PATH by local tooling kept outside this repo: jq by engram's setup
    # command, python3 by a hook that parses JSON payloads (without it the fallback
    # greps the whole blob and over-matches).
    pkgs.python3
    pkgs.jq

    # engram — MCP memory server over SQLite. Pinned release tarball, not in nixpkgs;
    # see ../pkgs/engram.nix.
    (pkgs.callPackage ../pkgs/engram.nix { })

    # Zen browser — "beta" is Zen's public release channel (NOT a pre-release; twilight is the
    # nightly). Package only (no programs.*), so chezmoi keeps owning the config.
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
  ];
}
