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

**Dotter** (Ghostty, Neovim): [`docs/dotter.md`](docs/dotter.md). Run **`./scripts/macos/bootstrap.sh`** first — it creates **`.dotter/local.toml`** from `local.toml.example` when missing (Dotter [requires](https://github.com/SuperCuber/dotter/wiki/1.-Getting-Started) it; the file is [gitignored](https://github.com/SuperCuber/dotter/wiki/1.-Getting-Started)). **Neovim** uses [Lazy.nvim](https://github.com/folke/lazy.nvim) + [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) (`<leader>` = space → **`Space g g`** LazyGit — needs **`lazygit`** from Homebrew). Deploy configs:

```bash
dotter deploy --dry-run -v
dotter deploy -v
```

**Auto version:** after you clone this repo, run **once**:

```bash
./scripts/git/install-git-hooks.sh
```

After that, every **`git push`** bumps the **PATCH** in [`VERSION`](VERSION) for you. More detail: [docs/developer-auto-version.md](docs/developer-auto-version.md).
