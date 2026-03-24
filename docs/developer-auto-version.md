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

**If PATCH doesn’t bump:** run `./scripts/git/install-git-hooks.sh` again and confirm `ls -l .git/hooks/pre-push` shows a symlink to `.githooks/pre-push`. Some IDEs run **push without hooks**—use the terminal for `git push`. You also need a **new** commit after the last auto bump before another PATCH bump.
