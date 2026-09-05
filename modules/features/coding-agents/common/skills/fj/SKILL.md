---
name: fj
description: Forgejo CLI for issues, pull requests, repositories, releases, Actions, organizations, and users on git.natsukium.com. Use whenever a request references git.natsukium.com or a Git remote hosted there; this is the Forgejo counterpart to the gh skill.
---

# fj - Forgejo CLI

Use `fj` for Forgejo-specific operations on `git.natsukium.com`. Use `git` for local commits, branches, and pushes.

## Select the host and repository explicitly

For unattended commands, avoid checkout inference and provide both the public host and repository:

```bash
fj -H https://git.natsukium.com issue search --repo owner/repo
fj -H https://git.natsukium.com issue view 'owner/repo#42'
```

Repository syntax depends on the command:

- Collection and create commands for issues and PRs accept `--repo owner/repo`.
- Commands acting on an existing issue accept a positional qualified reference such as `'owner/repo#42'`.
- Most commands acting on an existing PR accept the same qualified form. `pr assign` and `pr unassign` take it through `--pr` instead.
- Repository commands generally take `owner/repo` as a positional argument. Releases, tags, Actions, and wikis expose their own global `--repo`; check the relevant `--help` before composing less common commands.
- Convert a URL such as `https://git.natsukium.com/owner/repo/issues/42` or `/pulls/42` to `'owner/repo#42'`.

`-C`, `-R`, and the current directory infer the instance and repository from a Git remote. Some checkouts point at the internal host `manyara.tail4108.ts.net`, which requires Tailscale. Do not combine `-H` with `-R` when the public API endpoint is required: an explicitly selected remote can take precedence over `-H`. If a command fails against the internal host, connect Tailscale or retry with `-H https://git.natsukium.com` and an explicit repository or qualified reference.

## Authentication

```bash
fj auth list
fj -H https://git.natsukium.com whoami
fj auth login -H https://git.natsukium.com
fj auth add-token -H https://git.natsukium.com  # reads the token from stdin when omitted
fj auth logout -H https://git.natsukium.com
```

`fj auth list` should include `git.natsukium.com`. Never print or place an access token directly in a recorded command.

## Issues

```bash
# Search and create use --repo
fj -H https://git.natsukium.com issue search --repo owner/repo
fj -H https://git.natsukium.com issue search --repo owner/repo --state all "keyword"
fj -H https://git.natsukium.com issue search --repo owner/repo --labels bug --state open
fj -H https://git.natsukium.com issue create "Title" --repo owner/repo --body-file /tmp/issue.md

# Existing issues use a qualified reference
fj -H https://git.natsukium.com issue view 'owner/repo#42'
fj -H https://git.natsukium.com issue view 'owner/repo#42' comments
fj -H https://git.natsukium.com issue comment 'owner/repo#42' --body-file /tmp/comment.md
fj -H https://git.natsukium.com issue edit 'owner/repo#42' title "New title"
fj -H https://git.natsukium.com issue edit 'owner/repo#42' body "$(< /tmp/issue.md)"
fj -H https://git.natsukium.com issue edit 'owner/repo#42' labels --add bug --rm triage
fj -H https://git.natsukium.com issue close 'owner/repo#42' --with-msg "Closing reason"
```

## Pull requests

```bash
fj -H https://git.natsukium.com pr search --repo owner/repo --state all
fj -H https://git.natsukium.com pr create "Title" --repo owner/repo \
  --base main --head feature --body-file /tmp/pr.md

fj -H https://git.natsukium.com pr view 'owner/repo#5'
fj -H https://git.natsukium.com pr view 'owner/repo#5' diff
fj -H https://git.natsukium.com pr view 'owner/repo#5' comments
fj -H https://git.natsukium.com pr comment 'owner/repo#5' --body-file /tmp/comment.md
fj -H https://git.natsukium.com pr edit 'owner/repo#5' body "$(< /tmp/pr.md)"
fj -H https://git.natsukium.com pr review 'owner/repo#5' list --comments
fj -H https://git.natsukium.com pr assign --pr 'owner/repo#5' username
fj -H https://git.natsukium.com pr close 'owner/repo#5'
fj -H https://git.natsukium.com pr merge 'owner/repo#5' --method squash --delete
```

Inspect the PR and its diff before merging, and use the merge method requested by the user or repository policy. `pr checkout` is an exception to qualified references: it accepts a numeric ID and must run in the corresponding local Git repository.

## Other operations

```bash
fj -H https://git.natsukium.com repo view owner/repo
fj -H https://git.natsukium.com repo labels owner/repo view
fj -H https://git.natsukium.com release list --repo owner/repo
fj -H https://git.natsukium.com tag list --repo owner/repo
fj -H https://git.natsukium.com actions tasks --repo owner/repo
fj release --help
fj actions --help
```

## Important differences from gh

- `--repo` is not universal; use the command-specific forms above rather than translating a `gh` command mechanically.
- `issue create`, `issue comment`, `pr create`, and `pr comment` support `--body-file`. Issue and PR body edits do not, so pass file contents as the positional body argument.
- Bare issue or PR numbers are safe only when checkout inference is intentional and verified.
- In `fj` 0.6.0, `pr status` can panic while formatting Forgejo check data (`Unknown variable: $created_at`); use `pr view` and the Forgejo web UI if that occurs.
- Quote qualified references containing `#`.
- Use `gh`, not `fj`, for `github.com` remotes and URLs. If unsure, inspect `git remote -v` first.
