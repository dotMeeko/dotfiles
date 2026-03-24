# Auto version

To turn on automatic **PATCH** bumps on **`git push`**, run this **one time** (per clone / machine):

```bash
./scripts/git/install-git-hooks.sh
```

Then use **`git push`** as usual. **`VERSION`** is one line: `MAJOR.MINOR.PATCH`.

- **MAJOR** — breaking or large changes
- **MINOR** — new features, backward compatible
- **PATCH** — small fixes (bumped automatically on each push here)

Change **MAJOR** / **MINOR** in `VERSION` yourself when you need to.

## Commit message prefixes (optional)

Same idea as [Conventional Commits](https://www.conventionalcommits.org/). Put the type before a colon, then a short description.

| Prefix | When to use |
|--------|-------------|
| **`feat:`** | New behavior users care about (new tool, new config feature). |
| **`fix:`** | Bug fix or broken config corrected. |
| **`docs:`** | README, comments in this repo, help text only. |
| **`chore:`** | Maintenance that isn’t a user-facing fix or feature—deps, scripts, bump noise, tooling. |
| **`refactor:`** | Restructure without changing behavior. |
| **`style:`** | Formatting, whitespace, no logic change. |
| **`perf:`** | Performance improvement. |
| **`test:`** | Adding or changing tests. |
| **`ci:`** | CI / automation workflows. |

Examples: `feat: add starship config`, `fix: wrong path in install script`, `docs: clarify VERSION format`, `chore: bump version to 0.1.0` (manual), `chore: tweak git hooks`.

Automated version commits from this repo use **`chore: bump version to X.Y.Z [skip ci]`**—you don’t write those by hand.

---

**If PATCH doesn’t bump:** run `./scripts/git/install-git-hooks.sh` again and confirm `ls -l .git/hooks/pre-push` shows a symlink to `.githooks/pre-push`. Some IDEs run **push without hooks**—use the terminal for `git push`. You also need a **new** commit after the last auto bump before another PATCH bump.
