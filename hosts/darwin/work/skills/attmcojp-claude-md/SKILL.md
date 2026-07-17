---
name: attmcojp-claude-md
description: Change the org-level CLAUDE.md that governs every attmcojp repository. Its source of truth is a sops-encrypted file in the dotfiles repository, not the read-only copy at `~/src/work/github.com/attmcojp/CLAUDE.md`, so it cannot be edited in place. Use when asked to add, change, or remove a rule that should apply across attmcojp checkouts — 「組織のCLAUDE.mdに追記」「attmcojpの共通ルールを更新」 — and whenever a write to that path fails because the file is not writable.
---

# The attmcojp org-level CLAUDE.md

`~/src/work/github.com/attmcojp/CLAUDE.md` applies to every attmcojp checkout beneath it,
and it is not editable. It is a symlink into the sops-nix secret store, mode `0400`,
replaced wholesale at the next activation. A write there fails; forcing the write to
succeed — `chmod`, replacing the symlink, writing through it — produces a change that the
next activation discards without warning. **Never edit that path.**

The source of truth is `hosts/darwin/work/attmcojp-claude.md` in the dotfiles repository,
encrypted with sops. The rules are attmcojp-internal and that repository is public, which
is why the file is encrypted rather than stored as text, and why the procedure below
never lets the plaintext enter a working tree.

## Procedure

`sops` and `treefmt` live in the dotfiles devShell, not on the ambient PATH — bare
`make` fails with `make: sops: No such file or directory`. Run every command below
through `nix develop --command` **with the dotfiles repo as the working directory**:
the devShell hook acts on the cwd (installing pre-commit hooks, syncing files), so
launching it from another repository mutates that repository instead.

```
cd /Users/natsukium/src/private/github.com/natsukium/dotfiles
```

**1. Decrypt.** The path to the plaintext copy is printed on stdout.

```
nix develop --command make attmcojp-claude-md-open
```

**2. Edit that file** with the normal file tools. It sits under `~/.cache`, deliberately
outside every git repository. Do not copy it anywhere else, and do not paste its contents
into a commit message, PR, issue, or any other repository.

**3. Re-encrypt**, which also deletes the plaintext copy.

```
nix develop --command make attmcojp-claude-md-seal
```

`File has not changed, exiting` (make exits 2) means the edit was a no-op. That is a
signal, not a broken command — report it rather than retrying.

Sealing deletes the plaintext copy only on success. Any failure leaves it in place on
purpose, so an edit is never lost to a transient error; if the change is being abandoned
rather than retried, remove it by hand:

```
rm -f ~/.cache/dotfiles/secrets/attmcojp-claude.md
```

**4. Normalize formatting.** sops writes compact JSON, but the repo's pre-commit
treefmt hook runs with `--fail-on-change`, so committing the freshly sealed file fails
on the first attempt. Reformat it first — this only rewrites the whitespace of the
ciphertext JSON; decryption is unaffected:

```
nix develop --command treefmt hosts/darwin/work/attmcojp-claude.md
```

**5. Commit** in the dotfiles repository, on whatever branch it is currently on:

```
git -C /Users/natsukium/src/private/github.com/natsukium/dotfiles commit hosts/darwin/work/attmcojp-claude.md
```

Leave pushing to the user unless asked. See the next section for the message.

**6. Hand the activation back to the user.** The decrypted copy at
`~/src/work/github.com/attmcojp/CLAUDE.md` is stale until this machine's usual switch is
run, which needs sudo and is the user's call. Say so explicitly when reporting done —
otherwise the next session reads the old rules and nobody notices.

## The commit message

This is the one commit in the dotfiles repository whose message must **not** say why.
That repository's `CLAUDE.md` requires WHY in every message, and the repository is
public: a message describing which rule changed republishes in plaintext exactly what
the encryption exists to withhold. State that the org rules changed, and stop.

```
chore(claude-code): update attmcojp org rules
```

Add a body only when the reason is itself publishable. Anything naming a team, a
customer, an internal process, or the substance of the rule is not. When unsure, omit
the body — this exception is deliberate, and a future reader should not "fix" it by
filling in detail.

Reviewing the change means comparing plaintext, not reading `git diff`, which shows only
ciphertext. Re-run `attmcojp-claude-md-open` after sealing and check the file against
what was intended.

## What belongs in this file

Rules that hold for every attmcojp repository — shared conventions, organisation-wide
constraints. Anything true of one repository belongs in that repository's own
`CLAUDE.md`, where the team can review it in the open; putting it here hides it from
everyone but this machine. If it is unclear which of the two a rule belongs in, ask.

## Before reporting done

- `~/.cache/dotfiles/secrets` is empty — no plaintext copy survives.
- No repository has an untracked or staged file containing the rule text.
- The commit touches only `hosts/darwin/work/attmcojp-claude.md`, and its message does
  not restate what changed.
- The report tells the user that the rules take effect only after the next switch.
