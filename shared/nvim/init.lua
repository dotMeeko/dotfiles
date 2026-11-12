-- Neovim entry point — managed by dotter. LazyVim distro.
--
-- Everything here is portable: lazy.nvim bootstraps itself over git on first
-- launch and installs plugins into ~/.local/share/nvim, so this directory never
-- needs Nix. The only Nix-specific piece is lua/plugins/nixos.lua, and it is
-- gated on /etc/NIXOS.
require("config.lazy")
