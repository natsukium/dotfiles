# Literate Nix, code first

Status: design draft, written 2026-09-08. Nothing here is implemented in the
repository. The prototype under [`literate-nix/`](literate-nix/) is the
evidence for the claims below.

## Problem

This repository keeps its reasoning in Org documents and tangles the Nix out of
them. That preserves intent, but it costs me three things every day.

- Two artifacts for one fact. The `.org` and the tangled `.nix` must be kept in
  sync by a pre-commit hook and a Makefile.
- No LSP while writing. nixd and nil read `.nix`, not Org source blocks.
- Emacs is a build dependency. Tangling and export run through `emacs --batch`.

What I want to keep from Org: the why next to the code, chapter-level
narrative, the freedom to split one large block into named pieces, HTML
publishing, and translation through po4a.

## What marimo and Lean actually do

Both start from the same move. The source file is the only truth, and the
notebook or the document is a view computed from it.

- marimo stores a notebook as a plain `.py`. Markdown cells are Python
  expressions. Git diffs, LSP, and script execution all work because there is
  no second format.
- Lean keeps prose in doc comments and generates documents from the elaborated
  environment. It distinguishes `/-- … -/`, which attaches to the next
  declaration, from `/-! … -/`, which attaches to nothing and carries module
  or chapter prose.
- Lean has no noweb. A file is a flat sequence of declarations, so nothing
  needs to be spliced. Reordering is replaced by splitting into smaller
  declarations and composing them.
- Verso keeps prose first inside a single Lean file only because Lean's syntax
  is extensible. Nix has no syntax extension, so that route is closed.

The lesson is not how to express noweb. It is that splicing becomes unnecessary
once the language's own composition mechanism carries the pieces.

## Decision

Make `.nix` the source of truth and put the prose in comments.

- `/** … */` is an RFC 145 doc comment. It documents the node that follows it.
  nixd 2.9 already renders these on hover, and Nix 2.24 shows them in
  `nix repl :doc` for lambdas, so the editor side needs no new tooling.
- `/*! … */` is a free-floating comment for chapter and section prose. It
  attaches to nothing, mirrors Lean's `/-!`, and is an ordinary comment to
  every existing Nix tool.
- Comment bodies are CommonMark, with the indentation rule from RFC 145.
- A renderer produces the document view. Nothing produces Nix.

## Replacing noweb

Nix attribute sets are unordered, `let` is recursive, and evaluation is lazy,
so definition order is already free. Noweb was only doing textual splicing,
and the module system does that semantically.

| Org today                          | Code first                                  |
| ---------------------------------- | ------------------------------------------- |
| `{ <<disks>> <<domain>> }`         | `lib.mkMerge [ disks domain ]` or `imports` |
| `[ <<a>> <<b>> ]`                  | `a ++ b`                                    |
| `<<chunk>>` inside a script string | a `let` binding interpolated with `${}`     |

Usage in this repository as of 2026-09-08: 155 `<<…>>` references, of which
107 are in `modules/configuration.org`, 39 in `configuration.org`, and 8 in
`overlays/configuration.org`. Almost all of them split one large attribute set
into narrated sections. The Forgejo rewrite in the prototype shows the
translation: four chunks became four elements of one `lib.mkMerge`, each with
its own doc comment, and the two client chunks became plain bindings because
each already was one.

The cost is one extra level of nesting wherever `mkMerge` replaces a chunk.
Where a chunk maps to a single binding there is no cost.

Tangle targets that are not Nix: `features/shell/starship/async_prompt.fish`,
`features/shell/starship/starship.toml`, `po4a.cfg`, `scripts/*.sh`,
`scripts/*.el`, and 77 emacs-lisp blocks. All of them have a comment syntax,
so the same scheme applies with the matching tree-sitter grammar. Nothing in
the repository currently tangles to a format without comments.

## Rendering model

Each documented node becomes one row: prose on the left, the node's own source
on the right. Inside that source, every documented descendant is replaced by a
link to its own row. A free-floating comment becomes a row with an empty code
column.

I first tried the Docco model, which splits the file linearly at each doc
comment. It fails for Nix. A file is one expression, so the last section of a
nested block inherits every closing bracket of its ancestors, and a chapter
comment at the top of the file ends up attached to `{ ... }:`. Rendering by
node removes both problems, and the parent row shows the shape of the whole
block with its children as named holes. That is the Org outline with
`<<forgejo-ssh-port>>` recovered on the reading side instead of being written
on the source side.

## Tooling

### tree-sitter, not nixdoc

nixdoc parses RFC 145 comments but is built for a flat list of library
functions. Tested against a sample with nested attributes on 2026-09-08:

- The default flat mode documents top-level bindings only, function or not.
  It does not enter `services = { tailscale.enable = …; }`.
- Deep mode refuses to run without an explicit `include` list, and the entries
  it finds lose their parent path (`tailscale.enable`, not
  `services.tailscale.enable`).
- The output carries a start line but no end, so the code column would need a
  second parse anyway.
- Comments on list elements and free-floating chapter comments are out of
  scope.

tree-sitter gives a concrete syntax tree with byte spans, is error tolerant,
and has grammars for every language the repository tangles to. nixpkgs ships
`tree-sitter-grammars.tree-sitter-nix` and
`python3Packages.tree-sitter-language-pack`, so the prototype needed no build.
Nix semantics are not required at this layer because evaluation is delegated
to `nix eval` in the layer below.

One grammar quirk: tree-sitter-nix places a comment before the enclosing
`binding_set`, not before the first `binding`. The extractor descends to the
first child when the following node is a `binding_set`.

### Formatting

nixfmt leaves the rewritten Forgejo module unchanged, doc comments included.

### Cross references

Org links point at headings (`[[*SSH Client]]`). The prototype uses relative
file links, which is coarser. The intended mechanism is intra-doc links keyed
by attribute path, as rustdoc and Lean do with names:

- ``[`services.tailscale.extraUpFlags`]`` resolves to the row that documents
  that path, in whichever file it lives.
- A link that resolves to nothing is a lint error at render time. Org internal
  links only fail at export.
- The same path can be defined in several files because modules merge. The
  renderer lists every definition rather than picking one.

### Evaluation layer

This is the part with no existing counterpart, and the part that justifies the
move. Each attribute is a cell. `nix eval --json` is cell execution. For a
NixOS module the interesting value is the final `config.*` after merging,
which the Org view cannot show at all. Because Nix is pure and lazy, the
dependency graph that marimo has to approximate with static analysis is simply
the evaluation graph. `options.<path>.declarations` also gives exact link
resolution for option paths once this layer exists.

## Migration

The tangled `.nix` files already exist. Migration is a one-shot script that
moves each Org paragraph into the doc comment of the node its chunk produced,
turns noweb references into `mkMerge` elements or bindings, and deletes the
tangle machinery. The HTML site and the po4a pipeline then consume the
renderer's extraction instead of Org.

## Open questions

- Translation. po4a has no Nix module. The extractor can emit the doc comments
  as a gettext catalog, but that pipeline is unwritten.
- Whether nixd hover shows doc comments on non-lambda attributes in my own
  modules. Confirmed for nixpkgs functions, not yet for this case.
- Attribute path normalization for quoted and interpolated keys, for example
  `settings."git.natsukium.com"` and `ingress.${domain}`.
- Whether the Emacs configuration stays in Org. It is the one place where Org
  is also the native format of the tool being configured.
- `mkMerge` noise where a narrated chunk does not map to one binding, and
  whether that is acceptable or those sections should simply be documented
  as one.

## Prototype

- [`literate-nix/extract.py`](literate-nix/extract.py): tree-sitter walk,
  emits one JSON line per documented node with the elided source.
- [`literate-nix/render.py`](literate-nix/render.py): side-by-side HTML with
  highlight.js and child links.
- [`literate-nix/forgejo.nix`](literate-nix/forgejo.nix): the Forgejo feature
  rewritten code first from `modules/configuration.org`.

```
nix shell --impure --expr '(import <nixpkgs> {}).python3.withPackages (p: [ p.tree-sitter-language-pack p.markdown ])' \
  --command python3 render.py forgejo.nix
```
