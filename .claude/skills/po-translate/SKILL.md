---
name: po-translate
description: Orchestrate English→Japanese translation of po/ja.po — classify, delegate translation/review to subagents, iterate until clean
---

# PO Translation Orchestrator

Translate `po/ja.po` from English to Japanese for this literate Nix configuration
repository. This skill orchestrates the process: you classify entries yourself, then
delegate translation and review to subagents, iterating until the review passes.

## Phase 1: Classify (do this yourself)

Scan `po/ja.po` and classify every entry into three buckets.

### Skip (leave msgstr empty)

| PO type comment (`#. type:`)    | Reason                        |
|----------------------------------|-------------------------------|
| `paragraph in src`               | Code block content            |
| `keyword NAME` / `keyword name`  | Source block identifiers      |
| `keyword SETUPFILE`              | Org directive                 |
| `keyword PROPERTY`               | Property drawer value         |
| `keyword OPTIONS`                | Export option string          |
| `keyword STARTUP`                | Startup keyword               |
| `keyword INCLUDE`                | po4a handles path swap        |
| `property (*)`                   | Property values               |

Also skip: bare URLs as msgid, table cells with hardware models/hostnames/platforms.

### Already Translated

Non-empty msgstr — leave unchanged unless review flags them.

### Translate

Everything else: `paragraph`, `heading *`–`*****`, `plain list`, `paragraph in QUOTE/quote/example`,
`cell column N` with prose, `keyword title`.

### Grouping

Group translatable entries by primary source file into sequential batches:
1. `configuration.org`
2. `applications/emacs/init.org`
3. `overlays/configuration.org` + `applications/emacs/early-init.org` + `.github/README.org`
4. `modules/configuration.org`

Output a batch summary (entry counts, line ranges) before proceeding to Phase 2.

## Phase 2: Translate (delegate to subagents)

Spawn one Agent per batch, **sequentially** (wait for each to finish before starting
the next — they all edit the same file).

### Subagent prompt template

Include ALL of the following in each subagent's prompt:

1. The batch assignment: line range, list of msgid start lines to translate
2. The full content of these reference files (read them yourself first, then paste
   the content into the prompt — subagents cannot read skill reference files by path):
   - `.claude/skills/po-translate/references/glossary.md`
   - `.claude/skills/po-translate/references/style-guide.md`
   - `.claude/skills/po-translate/references/po-format.md`
3. These rules:

```
## Translation Rules

### What to translate
- paragraph, heading, plain list, paragraph in QUOTE/quote/example, cell with prose, keyword title

### What to leave empty (msgstr "")
- paragraph in src, keyword NAME/name, SETUPFILE/PROPERTY/OPTIONS/STARTUP/INCLUDE, property (*), bare URLs, proper nouns (hardware models, hostnames, platforms)

### PO format
- #, no-wrap entries: msgstr on single line
- Multi-line msgid: msgstr starts with "" then continuation lines
- Match approximate line structure of msgid
- Preserve \" escaping

### Org markup preservation
- [[url][desc]]: translate only desc, keep URL intact
- =code= and ~verbatim~: do NOT translate content inside markers
- *bold* / /italic/: translate text, keep markers
- \\\\: preserve in same position

### Terminology
- Follow the glossary strictly
- Nix terms (flake, derivation, overlay, home-manager) → keep English
- General technical terms with Japanese equivalents → use Japanese

### Register
- です/ます (desu/masu) polite form consistently
- Technical but accessible
- Faithfully translate "why" reasoning — core value of literate config

### Important
- Never modify msgid or comment lines (#., #:, #,)
- If entry already has correct translation, leave unchanged
- Preserve blank lines between entries
- Use the Edit tool for each translation
- After completing, read back modified sections to verify
```

## Phase 3: Review (delegate to subagent)

After all translation batches complete, spawn a review subagent.

### Review subagent prompt

Include these checks in the prompt:

1. **PO Syntax**: Run `msgfmt --check po/ja.po`
2. **Code blocks empty**: Verify `paragraph in src`, `keyword NAME/name`, directive
   keywords, `property (*)` all have empty msgstr
3. **Prose translated**: Verify `paragraph`, `heading`, `plain list` etc. have non-empty msgstr
4. **No-wrap compliance**: `#, no-wrap` entries have single-line msgstr
5. **Terminology**: No "フレーク"/"デリベーション"/"オーバーレイ" (should stay English);
   "configuration"→"設定", "declarative"→"宣言的" consistently
6. **Markup**: `[[`/`]]` count matches, URLs unchanged, `=code=`/`~verbatim~` preserved
7. **Register**: Sample entries for consistent です/ます form

The review subagent should:
- Fix minor issues (structural/terminology) directly
- Report translation quality issues with line numbers
- Re-run `msgfmt --check po/ja.po` after fixes

## Phase 4: Iterate (do this yourself)

Evaluate the review subagent's report:
- If **PASS** on all checks → done
- If issues remain → spawn targeted translation subagents to fix only the
  flagged entries, then re-run review (Phase 3)
- Repeat until clean

## Final Validation

After review passes:
```sh
msgfmt --check po/ja.po
po4a po4a.cfg
```
