---
name: ghq
description: Clone and reuse GitHub/GitLab repositories under a single managed root (`ghq root`) instead of fetching files one-by-one via `gh api`/`WebFetch` or scratch-cloning into `/tmp`. Use this skill whenever investigating, reading, grepping, or referencing source code from any remote repository — even for a single file. Triggers include "look at X's source", "how does X implement Y", "check the X repo", "find Z in nixpkgs/react/linux/etc.", or any moment a remote repo URL appears and you need to read more than one file from it. Skip only for one-shot GitHub API operations that have no source code in them (PR comments, issue bodies, workflow runs — those belong to the `gh` skill).
---

# ghq - Local Repository Management

`ghq` clones remote repositories into a predictable, deduplicated directory tree under `ghq root` (here: `~/src/private`, layout `<host>/<owner>/<repo>`). Once a repo is there, reading it is a local filesystem operation — no API calls, no rate limits, no re-download next time.

## Why this skill exists

When inspecting source code, the wasteful patterns are:

- **`gh api repos/.../contents/<file>` per file** — burns a request and base64 round-trip per read, can't grep across the tree, can't follow imports.
- **`git clone` into `/tmp` (or `mktemp -d`)** — re-downloads on every session, leaves the repo unfindable later, wastes bandwidth and disk.
- **`WebFetch` of `raw.githubusercontent.com` URLs** — same problem as `gh api`, plus no recursion.

`ghq get` solves all three: it's idempotent (no-op if the repo is already cloned), it puts the repo in a path you can find again with `ghq list`, and once local you can use `Read`, `Grep`, `Glob`, and `ast-grep` freely.

## The workflow

1. **Check first** — `ghq list <repo>` (or `ghq list -e <owner>/<repo>` for exact match). If it prints a path, the repo is already there; skip the clone.
2. **Clone if missing** — `ghq get <owner>/<repo>`. Add `--shallow` for one-off inspection of a specific commit's tree, or `--partial blobless` if the repo is huge (e.g., nixpkgs, linux, chromium) and you only need to navigate before reading a few files.
3. **Resolve the path** — `ghq list -p -e <owner>/<repo>` returns the absolute path. Use this with `Read`/`Grep`/`Glob`, not `cd`.
4. **Update only when needed** — `ghq get -u <owner>/<repo>` to pull latest. Don't update reflexively; a stale clone is usually fine for "how does X work" questions.

## Anti-patterns

<examples>
  <example type="bad">
    <description>Fetching files individually via the GitHub API</description>
    <bad>gh api repos/NixOS/nixpkgs/contents/pkgs/development/interpreters/python/default.nix</bad>
    <good>ghq get NixOS/nixpkgs && Read $(ghq list -p -e NixOS/nixpkgs)/pkgs/development/interpreters/python/default.nix</good>
  </example>
  <example type="bad">
    <description>Cloning into /tmp for "just this session"</description>
    <bad>git clone --depth 1 https://github.com/facebook/react /tmp/react</bad>
    <good>ghq get --shallow facebook/react  # ends up at ~/src/private/github.com/facebook/react, reusable</good>
  </example>
  <example type="bad">
    <description>Using WebFetch on raw.githubusercontent.com to read source</description>
    <bad>WebFetch https://raw.githubusercontent.com/owner/repo/main/src/foo.ts</bad>
    <good>ghq get owner/repo && Read $(ghq list -p -e owner/repo)/src/foo.ts</good>
  </example>
</examples>

## Good examples

<examples>
  <example>
    <user>Check how nixpkgs handles uv2nix</user>
    <agent>I'll make sure nixpkgs is cloned, then grep it locally.
`ghq get NixOS/nixpkgs` (no-op if present)
`rg -l uv2nix $(ghq list -p -e NixOS/nixpkgs)/pkgs`</agent>
  </example>
  <example>
    <user>Look at how React implements useEffect</user>
    <agent>I'll fetch React once and search the source tree.
`ghq get facebook/react`
Then `Grep` for `function useEffect` inside `$(ghq list -p -e facebook/react)`.</agent>
  </example>
  <example>
    <user>I want to see the changes in https://github.com/owner/repo/pull/42</user>
    <agent>That's a PR review, not source-code reading — using `gh` instead: `gh pr diff 42 --repo owner/repo`. (If I then need to explore the surrounding code, I'll `ghq get owner/repo`.)</agent>
  </example>
  <example>
    <user>The linux kernel has a function called vmalloc, can you find where it's defined?</user>
    <agent>Huge repo — partial clone keeps it tractable.
`ghq get --partial blobless torvalds/linux`
`rg -n 'void \*vmalloc\(' $(ghq list -p -e torvalds/linux)`</agent>
  </example>
</examples>

## When NOT to use ghq

- **PR/issue/workflow operations** — use `gh` (`gh pr view`, `gh issue view`, `gh run view`). Those aren't source code.
- **A single, never-revisited file from a documentation URL** — `WebFetch` is fine; cloning a repo for one README is overkill.
- **Inside this dotfiles repo itself** — already on disk; just `Read`/`Grep` directly.
