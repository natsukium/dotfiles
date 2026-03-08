#!/usr/bin/env bash
# Usage: check-git-changes <message> [git-diff-args...]
# Exits 1 if git diff finds changes, with instructions to stage them.
set -euo pipefail

message="$1"
shift

changed=$(git diff --name-only "$@")

if [ -n "$changed" ]; then
  echo "$message"
  echo "Changed files:"
  echo "$changed"
  echo ""
  echo "Please stage the changes and commit again:"
  echo "  git add $changed"
  exit 1
fi
