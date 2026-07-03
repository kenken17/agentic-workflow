#!/bin/bash
# Fetch a GitHub PR diff for review
# Usage: ./pr-diff.sh <PR-URL-or-PR-number>
set -euo pipefail

PR="$1"

# If it's a URL, extract the PR number
if [[ "$PR" =~ ^https?://github\.com/.*/pull/([0-9]+) ]]; then
    PR="${BASH_REMATCH[1]}"
    REPO=$(git remote get-url origin | sed -E 's|.*github\.com[:/]||; s|\.git$||')
    gh pr diff "$PR" --repo "$REPO" 2>/dev/null > /tmp/pr-diff.patch
elif [[ "$PR" =~ ^[0-9]+$ ]]; then
    gh pr diff "$PR" 2>/dev/null > /tmp/pr-diff.patch
else
    echo "Usage: $0 <PR-URL-or-PR-number>" >&2
    exit 1
fi

echo "/tmp/pr-diff.patch"