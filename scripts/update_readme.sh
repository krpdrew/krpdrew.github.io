#!/usr/bin/env bash
set -euo pipefail

# Script: scripts/update_readme.sh
# Purpose: Copy index.html at repo root to README.md
# Usage:
#   ./scripts/update_readme.sh
# In GitHub Actions this runs from the repository root by default.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC="$REPO_ROOT/index.html"
DST="$REPO_ROOT/README.md"

if [ ! -f "$SRC" ]; then
  echo "Error: $SRC not found" >&2
  exit 2
fi

cp -f "$SRC" "$DST"

echo "Copied $SRC -> $DST"
