# ~/.dotfiles

**Layout:** `Brewfile` at repo root (Homebrew Bundle), `docs/`, `scripts/git/` (hooks), `scripts/macos/` (bootstrap + defaults), `.dotter/`, `.githooks/`, `VERSION`.

**macOS bootstrap** (Homebrew → `brew bundle`), from the repo root:

```bash
./scripts/macos/bootstrap.sh
```

**macOS defaults** (optional but recommended once per machine — review [`scripts/macos/defaults.sh`](scripts/macos/defaults.sh) first):

```bash
./scripts/macos/defaults.sh
```

**Auto version:** after you clone this repo, run **once**:

```bash
./scripts/git/install-git-hooks.sh
```

After that, every **`git push`** bumps the **PATCH** in [`VERSION`](VERSION) for you. More detail: [docs/developer-auto-version.md](docs/developer-auto-version.md).
