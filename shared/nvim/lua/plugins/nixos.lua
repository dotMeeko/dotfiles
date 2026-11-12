-- NixOS only: turn mason.nvim off.
--
-- mason installs language servers as prebuilt, dynamically-linked binaries that
-- expect /lib64/ld-linux-x86-64.so.2 and an FHS layout. Neither exists on NixOS,
-- so every server it downloads fails to exec. The servers come from Nix instead
-- (nix/home/packages.nix: lua-language-server, nil, nixfmt-rfc-style, statix,
-- stylua, shfmt); LazyVim's lsp spec already guards every mason call behind
-- `LazyVim.has("mason-lspconfig.nvim")`, so disabling it is a supported path and
-- lspconfig simply uses whatever is on PATH.
--
-- Gated rather than deleted: this same config is deployed on macOS and Windows,
-- where mason works fine and is the easier way to get a server.
if not (vim.uv or vim.loop).fs_stat("/etc/NIXOS") then
  return {}
end

return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
}
