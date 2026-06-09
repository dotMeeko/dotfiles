# Versioning

The repo version lives in [`VERSION`](../VERSION) as a single `MAJOR.MINOR.PATCH`
line. The **PATCH** bumps automatically on every commit via a pre-commit hook, so
the new version travels inside the same commit you push — no lag on the remote.

## Files involved

| File | Role |
|------|------|
| [`VERSION`](../VERSION) | Source of truth — one line `MAJOR.MINOR.PATCH`. |
| [`scripts/git/bump-version.sh`](../scripts/git/bump-version.sh) | Increments PATCH and prints the new value. |
| [`.githooks/pre-commit`](../.githooks/pre-commit) | Bumps PATCH and stages `VERSION` into the commit being made. |
| [`scripts/git/install-git-hooks.sh`](../scripts/git/install-git-hooks.sh) | Installs the hook into the current clone. |

The hook stays inert until installed — Git only runs `.git/hooks/`, which isn't
tracked, so a fresh clone needs the install step below.

## Setup (once per clone)

```bash
./scripts/git/install-git-hooks.sh   # symlinks .git/hooks/pre-commit -> ../../.githooks/pre-commit
ls -l .git/hooks/pre-commit          # verify the symlink
```

## Bumping

- **MAJOR** / **MINOR** — edit [`VERSION`](../VERSION) by hand for breaking or
  feature changes.
- **PATCH** — bumped automatically on each commit and included in it.

To skip the bump for one commit:

```bash
SKIP_VERSION_BUMP=1 git commit -m "..."
```

## Troubleshooting

If PATCH doesn't bump:

```bash
./scripts/git/install-git-hooks.sh   # re-install
ls -l .git/hooks/pre-commit          # confirm the symlink exists
```

- Some IDEs commit without hooks — commit from a terminal instead.
- `SKIP_VERSION_BUMP=1` disables the bump for that commit.
