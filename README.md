# ~/.dotfiles

**Layout:** `Brewfile` at repo root (Homebrew Bundle), `docs/` ([`docs/dotter.md`](docs/dotter.md)), `scripts/git/` (hooks), `scripts/macos/` (bootstrap + defaults), `.dotter/`, `.githooks/`, `VERSION`.

**macOS bootstrap** (Homebrew → `brew bundle`), from the repo root:

```bash
./scripts/macos/bootstrap.sh
```

**macOS defaults** (optional but recommended once per machine — review [`scripts/macos/defaults.sh`](scripts/macos/defaults.sh) first):

```bash
./scripts/macos/defaults.sh
```

**Dotter** (Ghostty, Neovim): [`docs/dotter.md`](docs/dotter.md). Run **`./scripts/macos/bootstrap.sh`** first — it creates **`.dotter/local.toml`** from `local.toml.example` when missing (Dotter [requires](https://github.com/SuperCuber/dotter/wiki/1.-Getting-Started) it; the file is [gitignored](https://github.com/SuperCuber/dotter/wiki/1.-Getting-Started)). **Neovim** is [LazyVim](https://www.lazyvim.org/) ([starter](https://github.com/LazyVim/starter) in `packages/nvim/`) plus [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) (`<leader>` = space → **`Space g g`**). `brew bundle` installs CLI deps from the [LazyVim requirements](https://www.lazyvim.org/) where we use Homebrew (`neovim`, `lazygit`, `fzf`, `fd`, `ripgrep`, `tree-sitter`, Ghostty). **Git** (≥ 2.19) and **`curl`** usually come with macOS / **Xcode CLT** — no extra formula. **Not** from `brew bundle`: **CLT** (C compiler for Treesitter — `xcode-select --install`), **Nerd Font** (optional). Deploy configs:

```bash
dotter deploy --dry-run -v
dotter deploy -v
```

If you used a different Neovim config before, LazyVim recommends moving aside old data once: `mv ~/.local/share/nvim ~/.local/share/nvim.bak` (see [LazyVim README](https://github.com/LazyVim/LazyVim#getting-started)). Then open `nvim` and let plugins install; use **`:LazyExtras`** for optional LazyVim add-ons.

**Auto version:** after you clone this repo, run **once**:

```bash
./scripts/git/install-git-hooks.sh
```

After that, every **`git push`** bumps the **PATCH** in [`VERSION`](VERSION) for you. More detail: [docs/developer-auto-version.md](docs/developer-auto-version.md).
