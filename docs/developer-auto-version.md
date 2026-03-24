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

**If PATCH doesn’t bump:** check `git config core.hooksPath` prints `.githooks`. Push from a terminal (some IDEs use **push without hooks**). You need a **new** commit on top of the last auto bump—pushing again with nothing new only uploads the pending bump commit.
