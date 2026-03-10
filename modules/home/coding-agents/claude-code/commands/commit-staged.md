---
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git commit:*), Bash(git add:*)
argument-hint: intention
description: Review staged changes and create commit with appropriate message
model: haiku
---

## Context

- Current git status: !`git status --short`
- Staged changes: !`git diff --cached --stat`
- Detailed staged diff: !`git diff --cached`
- Recent commit history: !`git log --oneline -10`

## Your task

Based on the staged changes above, create a commit with an appropriate message.

If no staged changes exist, inform the user and do not create an empty commit.

Otherwise, you MUST execute `git commit -m "..."` using the Bash tool to actually create the commit. Do NOT just output the commit message — you must run the command.

If the commit fails because a pre-commit hook modified files (e.g. formatters, linters), re-stage the modified files with `git add` and retry the same `git commit` command. Do NOT amend the previous commit — the failed commit was never created.

The commit message should:
1. Follow the repository's existing commit message style (refer to recent commits)
2. Explain WHY the change was made, not just what changed
3. Be concise but informative

## Additional Instructions

$ARGUMENTS
