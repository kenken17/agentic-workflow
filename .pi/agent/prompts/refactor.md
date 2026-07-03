---
description: "Refactor code while preserving behavior — simplify, deduplicate, restructure"
argument-hint: "<file-or-directory>"
---
Refactor the following target: $@

Load the refactor skill first.

Process:
1. Read the target code thoroughly
2. Identify specific problems (duplication, complexity, poor naming, dead code)
3. Run existing tests to establish a baseline
4. If no tests exist, write characterization tests capturing current behavior
5. Refactor in small steps — one technique at a time
6. Run tests after each step. If red, undo and try differently
7. Run lint and typecheck
8. Diff review — confirm only intended changes are present

Do NOT fix bugs or add features during the refactor. Those go in separate commits.

Commit with message: `refactor: <what and why>`