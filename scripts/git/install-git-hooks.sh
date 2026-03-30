#!/usr/bin/env bash

# Install the version-bump hook into Git's default hook dir (symlink to tracked .githooks).
# Run once per clone: ./scripts/git/install-git-hooks.sh
#
# Uses .git/hooks/pre-push instead of core.hooksPath so all Git clients (CLI, IDE) pick it up reliably.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# If this was set, Git ignores .git/hooks — unset so the symlink below is used.
git config --local --unset-all core.hooksPath 2>/dev/null || true

mkdir -p .git/hooks
ln -sf ../../.githooks/pre-push .git/hooks/pre-push

chmod +x .githooks/pre-push scripts/git/bump-version.sh scripts/git/install-git-hooks.sh scripts/macos/bootstrap.sh scripts/macos/defaults.sh 2>/dev/null || true

echo "Installed: .git/hooks/pre-push -> .githooks/pre-push"
echo "If your IDE still skips hooks, push from a terminal or disable \"skip hooks\" for push."
