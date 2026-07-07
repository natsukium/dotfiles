---
name: org-literate
description: Prose standard for this repository's literate Org configuration documents — first-person narrative voice, scope per setting, paragraph structure, logical rigor, restraint, and banned LLM-sounding English. Use when writing, rewriting, or reviewing prose in *.org files (configuration.org, modules/, overlays/, README).
---

# Prose Standard for Literate Org Documents

Rules for writing and revising prose in this repository's Org documents.
Adapted from k16shikano's japanese-tech-writing standard
(https://gist.github.com/k16shikano/fd287c3133457c4fd8f5601d34aa817d),
translated to English and to the register of a personal configuration narrative.

## Formatting

- Fill-wrap paragraphs at roughly 85 columns, matching the surrounding text.
- Org markup: =code= for commands, option paths, and file names; ~verbatim~ for
  literal values; `[[url][description]]` for links, with proper nouns kept as
  the description.
- Fragments of code, diffs, logs, and config belong in src blocks, not inline
  prose.
- Bold a repo-specific term at its first definition; refer to it in plain text
  afterwards.

## Voice

This configuration is a story told by its owner. The reader is a guest browsing
someone's dotfiles, not a student reading a manual.

- Narrate decisions in the first person: "I pin this to 0.9 because the 1.x
  series broke tangling", not "the package is pinned due to breakage".
- Describe what software does in plain third person: "niri scrolls windows
  horizontally". First person is for choices, history, and opinions.
- Real history is welcome ("after the second time a brew upgrade broke Emacs,
  I moved everything to Nix") — but only if it actually happened.
- Avoid "we": there is only one author here. Avoid tutorial imperatives
  ("install X, then run Y") unless the section genuinely is a procedure.
- Opinions may be blunt. "zsh's completion setup wore me down" is better
  material than a neutral feature comparison.

## Scope per setting

- Most settings need one or two sentences: what it enables and the visible effect.
- Reserve the full problem-and-alternatives account for non-obvious trade-offs:
  architectural choices, package pins, temporary workarounds, forks.
- Prose explains why and why-not-the-alternative; the code block already shows
  what. Never paraphrase the code line by line.

## Paragraphs and argument

- One topic per paragraph. The first sentence tells the reader what the
  paragraph is about.
- Make the logical link to the previous paragraph explicit at the start
  ("So", "In practice", "But that same failure…").
- Argue in one direction: handle objections first, then state the conclusion
  once. Do not conclude, rebut, and re-conclude.
- When rejecting an alternative, give the concrete reason in one sentence — a
  counterfactual often works ("with zsh I would have needed three plugins for
  this").

## Logical rigor

- Every causal claim carries its mechanism. "Enabling A breaks B" is not an
  explanation; say through what.
- Do not promise unconditionally what only holds conditionally. Prefer
  "usually", "as long as", "when X holds" over blanket guarantees.
- Do not flatten hedges into assertions when revising. "This seems to be a
  scheduler issue" stays hedged unless the surrounding text establishes it.
- One name per concept, document-wide. Once a section introduces a term
  (profile, feature, overlay), keep using it; do not fall back to vague words
  like "the tool" or "the AI".
- Distinct things stay distinct: two pins with two different reasons are not
  "the same workaround applied twice".

## Reader load

- In prose, prefer the plain description ("the launcher") over the exact
  identifier when precision isn't needed; the code block carries the exact
  names.
- Skip decorative precision — dates, sizes, version numbers — unless the number
  itself is the point (a 100 MiB request cap that forced a redesign earns its
  place).
- Before adding a second example or scene, say what the first one didn't cover.

## Restraint

- Bold sparingly: one or two per section, at logical pivots only.
- A dry fact is usually enough. Save the storytelling beat — a short punchy
  sentence, an exclamation — for a genuine turning point: a migration, a fork,
  a disaster. At most once per section.
- No rhetorical questions as transitions, no suspense-building
  ("little did I know…") as a habit.

## Banned LLM English

These phrases add a "sounds thorough" veneer without adding content. Delete or
replace on sight; after drafting, re-read against this list.

- **Previews and wrap-ups**: "In this section we will explore…", "It's important
  to note that…", "It's worth noting…", "In summary", "Overall" (when it only
  restates). State the point directly.
- **Empty adjectives**: "crucial", "essential", "key", "robust", "seamless",
  "comprehensive", "powerful", "cutting-edge" — importance claimed, not shown.
- **Empty verbs**: "delve into", "dive deep", "leverage", "utilize", "harness",
  "streamline", "unlock", "empower", "elevate". Use the plain verb: "use", "run".
- **Connective tics**: chains of "Additionally / Moreover / Furthermore";
  "when it comes to"; "in terms of". If two facts share a role, join them in
  one sentence instead of stacking connectives.
- **Formula contrasts**: "not just X, but Y" and "it's not about X — it's about
  Y" as a reflex; rule-of-three lists ("fast, simple, and reliable") where the
  third item adds nothing.
- **Filler glue**: "This ensures that…", "This allows for…" when the sentence
  only restates the previous one. Keep it only when it adds the mechanism.
- **Contentless intensifiers**: "very", "extremely", "incredibly",
  "significantly".
- Em dashes are fine, but not as the default connector — more than one per
  paragraph reads as generated text. Prefer a comma, parentheses, or two
  sentences.

## Headings

A heading names the component or the question the section answers ("Binary
cache", "Why not cachix"). Not a procedure ("Setting it up"), and not a spoiler
that states the conclusion.

## Honesty

- Do not invent history or motives. If the reason for an old setting is
  forgotten, say so: "I no longer remember why this is here, and I'm afraid to
  remove it" is honest and useful.
- Do not describe as tested what wasn't. "Should also work on darwin, though I
  haven't tried" keeps the reader oriented.
- A workaround is a workaround: name the upstream issue and the condition for
  removing it.
