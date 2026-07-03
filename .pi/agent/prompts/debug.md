---
description: "Systematically debug an issue — understand, reproduce, isolate, fix"
argument-hint: "<error-message-or-description>"
---
Debug the following issue: $@

Process:
1. UNDERSTAND: Read the error message and relevant code. Understand what the code is supposed to do vs what it's doing.
2. REPRODUCE: Find a reliable way to reproduce the issue (command, test case, script).
3. ISOLATE: Narrow down the cause. Use logging, print statements, or a debugger. Don't guess — verify.
4. FIX: Make the minimal change that fixes the issue without introducing new problems.
5. VERIFY: Run the reproduction step to confirm the fix. Run existing tests to confirm no regressions.
6. TEST: Write or update a test that would have caught this bug.
7. COMMIT: `fix: <description of what was wrong and how it was fixed>`

Do not skip the UNDERSTAND and REPRODUCE steps. Fixing without understanding leads to whack-a-mole.