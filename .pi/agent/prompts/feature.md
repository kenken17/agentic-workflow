---
description: "Build a new feature end-to-end with planning, TDD, and verification"
argument-hint: "<feature-description>"
---
Build the following feature: $@

Load the feature-builder skill first.

Process:
1. Read relevant existing code to understand patterns and conventions
2. Identify files to modify and create
3. Write a brief implementation plan and present it to me
4. Wait for my confirmation before proceeding
5. Write tests first (if project has a test framework)
6. Implement the feature
7. Run lint, tests, typecheck/build
8. Manually verify the feature works
9. Commit with `feat:` prefix
10. Summarize what was done