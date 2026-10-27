-- init.lua — portable Neovim config, managed by chezmoi. No Nix or plugins required.
-- Sensible defaults that work on any distro.

vim.g.mapleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.scrolloff = 5
opt.clipboard = "unnamedplus"
opt.undofile = true

-- Clear search highlight on <Esc>
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
