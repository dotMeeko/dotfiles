#!/usr/bin/env bash

# Install the version-bump pre-commit hook (run once per clone).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# If this was set, Git ignores .git/hooks — unset so the symlink below is used.
git config --local --unset-all core.hooksPath 2>/dev/null || true

mkdir -p .git/hooks
rm -f .git/hooks/pre-push   # drop the old pre-push hook if migrating
ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit

chmod +x .githooks/pre-commit scripts/git/bump-version.sh scripts/git/install-git-hooks.sh 2>/dev/null || true

echo "Installed: .git/hooks/pre-commit -> .githooks/pre-commit"
echo "If your IDE skips hooks, commit from a terminal or disable \"skip hooks\" for commit."
