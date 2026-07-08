---
description: "Review code changes via the code-reviewer sub-agent"
argument-hint: "[staged|<PR-URL>|<file-paths>]"
---
Review the following code changes by delegating to the code-reviewer sub-agent.

Target: $@

If no argument: review all uncommitted changes (delegate: "review git diff HEAD")
If "staged": review staged changes (delegate: "review git diff --cached")
If a PR URL: delegate: "review the PR diff from: <URL>"
If file paths: delegate: "review these files: <paths>"

Use the delegate tool with agent="code-reviewer" and pass the full context including what to review and the working directory.