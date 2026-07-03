---
description: "Review code changes for bugs, security, performance, and style"
argument-hint: "[staged|<PR-URL>|<file-paths>]"
---
Review the following code changes. Load the code-review skill first.

Target: $@

If no argument provided, review all uncommitted changes with `git diff HEAD`.
If "staged", review `git diff --cached`.
If a PR URL, fetch the diff with `gh pr diff`.
If file paths, review those files directly.

For each file changed, evaluate:
1. Correctness — logic errors, edge cases, null access, race conditions
2. Security — injection, hardcoded secrets, unsafe input handling
3. Performance — N+1 queries, unnecessary allocations, O(n^2) patterns
4. Maintainability — dead code, complexity, naming, error handling
5. Testing — new code without tests, weak assertions, missing edge cases

Output findings grouped by severity (Critical / Warnings / Suggestions), then give a one-line verdict: APPROVE, REQUEST CHANGES, or NEEDS DISCUSSION.