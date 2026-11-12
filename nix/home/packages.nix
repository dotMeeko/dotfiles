# home-manager profile. Per Architecture — ONLY `home.packages` (packages),
# no `programs.*`, so Nix never generates configs and never fights dotter.
{ pkgs, inputs, ... }:
{
  home.packages = [
    pkgs.git
    pkgs.vim

    # Neovim + what LazyVim needs around it. The config itself lives in
    # shared/nvim/ and is owned by dotter (no programs.neovim, per Architecture).
    #
    # 0.12.4 from stable is enough: LazyVim refuses to start below 0.11.2.
    pkgs.neovim
    # nvim-treesitter is on its `main` branch in current LazyVim, which COMPILES
    # parsers on :TSUpdate instead of shipping them — hence a C compiler and the
    # tree-sitter CLI. Without these, highlighting silently stays off.
    pkgs.gcc
    pkgs.tree-sitter
    # Pickers and the grep/files sources behind <leader><space> and <leader>sg.
    pkgs.ripgrep
    pkgs.fd
    # <leader>gg opens this.
    pkgs.lazygit

    # Language servers, formatters and linters. These come from Nix rather than
    # mason.nvim, which is disabled on NixOS — it downloads FHS binaries that
    # cannot exec here. See shared/nvim/lua/plugins/nixos.lua for the gate.
    #
    # lua-language-server + stylua: LazyVim core (it configures lua_ls itself).
    pkgs.lua-language-server
    pkgs.stylua
    # shfmt: LazyVim core formats shell with it (relevant — shared/bashrc).
    pkgs.shfmt
    # nil + nixfmt + statix: the lang.nix extra, imported in config/lazy.lua.
    # That extra asks for nil_ls, not nixd; the package is `nil`. And nixfmt is
    # the RFC-style formatter now — nixfmt-rfc-style is an alias for it in 26.05
    # and warns on evaluation.
    pkgs.nil
    pkgs.nixfmt
    pkgs.statix

    # Noctalia — the desktop shell (bar, launcher, notifications, lock screen)
    # that niri starts via spawn-at-startup. From unstable on purpose: 26.05 pins
    # 5.0.1 while upstream is on 5.4.1, and the IPC surface these keybinds use
    # (`noctalia msg panel-toggle ...`) was checked against 5.4.1.
    #
    # Replaced DankMaterialShell, which owned parts of niri's own config — its
    # monitor profiles and its dms/input.kdl include were the direct cause of a
    # crawling remote mouse and a dead layout toggle. Noctalia does not write to
    # config.kdl and does not manage outputs; that stays niri's job.
    pkgs.unstable.noctalia

    # Standard GTK file manager.
    pkgs.nautilus

    # dotter — owns all dotfiles per the README. Replaced chezmoi, whose source
    # layout had to encode every target path in the filename (dot_config/...) and
    # could not be configured otherwise; see .dotter/global.toml for the mapping.
    pkgs.dotter

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
    # nightly). Package only (no programs.*), so dotter keeps owning the config.
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
  ];
}
