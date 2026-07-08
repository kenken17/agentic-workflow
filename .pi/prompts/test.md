---
description: "Write or run tests via the test-engineer sub-agent"
argument-hint: "[<file-or-feature>]"
---
Handle testing for: $@

If a file or feature is specified:
- delegate("test-engineer", "write tests for: $@. Read the code first, identify the test framework, cover happy paths, edge cases, and error cases.")

If no argument:
- delegate("test-engineer", "run the project's test command and report results.")