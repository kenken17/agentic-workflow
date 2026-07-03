---
description: "Write or run tests for the specified code"
argument-hint: "[<file-or-feature>]"
---
Work with tests for: $@

If a file or feature is specified:
1. Read the target code
2. Identify the test framework used in this project (check package.json, pyproject.toml, Cargo.toml, go.mod, etc.)
3. Write tests covering:
   - Happy path / normal behavior
   - Edge cases (empty input, boundary values, large input)
   - Error cases (invalid input, failure modes)
   - Any existing untested branches
4. Run the tests and ensure they pass

If no argument:
1. Run the project's test command
2. Report results — pass/fail counts, any failures with details
3. If tests fail, offer to investigate

Test naming: follow existing conventions in the project. If no conventions exist, use descriptive names (e.g. `test_user_cannot_login_with_wrong_password`).