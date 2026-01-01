---
name: gh
description: GitHub CLI for pull requests, issues, releases, workflows, and repository operations. Use for creating PRs, managing issues, viewing repository information, and accessing GitHub URLs.
---

# gh - GitHub CLI

gh is the official GitHub command-line interface for interacting with GitHub repositories, issues, pull requests, and more.

## Triggers

pull request, PR, issue, GitHub API, release, workflow, repository info, GitHub operations, GitHub URL

## When to Use

Creating PRs, managing issues, viewing repository information, releases, accessing GitHub URLs

## Examples

<examples>
  <example>
    <user>Create a PR for this repository</user>
    <agent>I'll create a PR using gh command: `gh pr create --title "feat: add new feature" --body "Description of changes"`</agent>
  </example>
  <example>
    <user>Show me recent issues</user>
    <agent>I'll list issues with gh: `gh issue list --limit 10 --state all`</agent>
  </example>
  <example>
    <user>Check the review comments on this PR</user>
    <agent>I'll view PR comments with gh: `gh pr view --comments`</agent>
  </example>
  <example>
    <user>Read the discussion in https://github.com/owner/repo/issues/12345</user>
    <agent>I'll fetch the issue with gh: `gh issue view 12345 --repo owner/repo --comments`</agent>
  </example>
  <example>
    <user>Can you check what's in this PR? https://github.com/owner/repo/pull/42</user>
    <agent>I'll view the PR details with gh: `gh pr view 42 --repo owner/repo`</agent>
  </example>
  <example>
    <user>Check the workflows in this repository</user>
    <agent>I'll list workflows with gh: `gh workflow list`</agent>
  </example>
</examples>
