---
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git commit:*)
argument-hint: intention
description: Review staged changes and create commit with appropriate message
model: claude-sonnet-4-20250514
---

## Context

- Current git status: !`git status --short`
- Staged changes: !`git diff --cached --stat`
- Detailed staged diff: !`git diff --cached`
- Recent commit history: !`git log --oneline -10`

## Your task

Based on the staged changes above, create a commit with an appropriate message that:
1. Follows the repository's existing commit message style (refer to recent commits)
2. Explains WHY the change was made, not just what changed
3. Is concise but informative
4. If no staged changes exist, inform the user and do not create an empty commit

## Additinoal Instructions

$ARGUMENTS
