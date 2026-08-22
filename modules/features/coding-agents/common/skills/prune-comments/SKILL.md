---
name: prune-comments
description: Delete code comments that restate the code, narrate uncontested decisions, or explain frameworks, so the few load-bearing comments stay visible. Load when asked to prune, trim, clean up, or reduce comments (「コメントを整理/削除」), when the user says comments are noisy, stale, or excessive, or when writing new code in a codebase that values sparse comments. Works in any language.
---

# Pruning Code Comments

Over-commented code is worse than under-commented code: the noise buries
the few comments that carry real information, and every comment is a
liability that drifts from the code it describes. The goal of a prune is
not "fewer comments" as a statistic — it is that every surviving comment
is one the reader must not miss.

## The survival test

A comment survives in exactly two cases, stated in one or two plain
sentences:

1. **Why-not**: it names an alternative a competent reader would
   plausibly reach for and states its non-obvious failure.
   ("Not the builtin NAT: NAT offers no host->guest path.")
2. **An invariant the code cannot show**: a value that must agree with
   the other side of a boundary (another file, process, protocol, or
   tool) and what breaks if they drift; an environment, OS, or
   third-party quirk the code works around; an exit-code or format
   contract; an ordering/locking constraint whose violation breaks
   something non-locally ("holding this lock is what licenses X to
   do Y").

Exception: test code is the one place a WHAT comment is welcome — the
test name plus at most a short comment saying which promise the test
pins. Everything else in the test body follows the same rules as
production code.

"The reason isn't visible in the code" is NOT sufficient. Every naming,
factoring, and structuring decision has a reason, and none of them get a
comment. If nobody would seriously contest the decision, the "because"
is narration, not information.

## DELETE

Delete the whole comment, or trim a mixed comment to its surviving
clause:

1. **Paraphrase of the code or signature.** Doc comments that restate
   what the name and types already say ("returns the current PID, or 0
   when not running"; "accepts PORT or HOST:PORT").
2. **Generic language / stdlib / framework knowledge.** How the
   framework wires things, what a stdlib call guarantees, what a
   well-known option means — anything true of every project using the
   tool, not of this software. Tutorials belong in the tool's docs.
3. **History.** "was", "previously", "no longer", "renamed from",
   before/after framing, compatibility notes for versions nobody runs.
   `git log` owns the past; a comment that only makes sense against a
   previous version of the code is stale the day it lands.
4. **Rationale for uncontested decisions.** Why a struct carries a
   field, why a function was split, "X rather than Y" where nobody
   would seriously try Y or the benefit is obvious.
5. **Narration of visible behavior.** What the next line does, the
   shape a format string builds, restating a condition in prose.
6. **Reviewer-addressed justification.** "This is safe because…",
   change-relative framing — that argument belongs in the commit
   message, not the source.
7. **Duplicates.** An invariant already stated at its authoritative
   site (the usage site, the boundary definition, a central helper)
   does not get copies at every mention. Keep one, at the site a
   reader hits first when the invariant matters.

## Never touch

- Directives: `//go:build`, `//nolint`, `# shellcheck disable`,
  `# type: ignore`, `eslint-disable`, `pragma`, and their kin.
- String literals — including error messages and test assertion strings
  that happen to sound like narration.
- User-facing surfaces that live in comment syntax or near it: CLI
  help/usage strings, option `description` fields, and doc comments on
  the public API of a published library (godoc/rustdoc/JSDoc that users
  actually read). An internal function's paraphrase-doc is still
  deletable; a published API's reference doc is not.
- License and copyright headers.

## When unsure

Re-run the survival test: boundary agreements and environment quirks
stay; justification of local structure and narration of behavior goes.
If a repo's own guidelines (CLAUDE.md, contributing docs) are stricter
or looser, they win.

<examples>
  <example type="delete">
    <bad>// parseConfig reads the config file and returns a Config struct.</bad>
    <why>Signature paraphrase — the name and types already say this.</why>
  </example>
  <example type="delete">
    <bad>// flake-parts calls perSystem once per system in `systems`, passing the pkgs for that system.</bad>
    <why>Framework tutorial, true of every flake-parts project.</why>
  </example>
  <example type="delete">
    <bad>// Previously this used polling; now we rely on inotify events.</bad>
    <why>History. Present-tense contract or nothing.</why>
  </example>
  <example type="keep">
    <good>// Dots are excluded from names because the DNS router splits hostnames on dots.</good>
    <why>Cross-boundary agreement: the constraint lives in another component.</why>
  </example>
  <example type="keep">
    <good>// --foreground is mandatory: without it the child detaches in turn and forks forever.</good>
    <why>Why-not with a non-obvious failure.</why>
  </example>
</examples>
