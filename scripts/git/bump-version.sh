#!/usr/bin/env bash

# Bump PATCH in VERSION (MAJOR.MINOR.PATCH). Prints new version to stdout.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION_FILE="$ROOT/VERSION"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "0.1.0" >"$VERSION_FILE"
fi

CURRENT="$(tr -d ' \n\r' <"$VERSION_FILE")"

if [[ "$CURRENT" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
else
  echo "Error: invalid VERSION format: ${CURRENT} (expected MAJOR.MINOR.PATCH)" >&2
  exit 1
fi

NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
echo "$NEW_VERSION" >"$VERSION_FILE"
echo "$NEW_VERSION"
