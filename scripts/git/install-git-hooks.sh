#!/usr/bin/env bash

# Point this repo at .githooks/ so hooks are tracked in git.
# Run once after clone: ./scripts/git/install-git-hooks.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

git config core.hooksPath .githooks
echo "core.hooksPath set to .githooks (this repository only)"

chmod +x .githooks/pre-push 2>/dev/null || true
echo "Hook: pre-push (PATCH bump before push)"
