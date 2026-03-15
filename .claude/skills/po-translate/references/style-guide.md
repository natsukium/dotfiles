# Translation Style Guide

Conventions for translating this literate Nix configuration from English to Japanese.

## Register

- **Politeness level**: です/ます (desu/masu) form throughout
  - Matches the existing translated entries in `po/ja.po`
  - Appropriate for technical documentation that is public-facing
- **Avoid**: だ/である (da/de aru) form, casual speech, overly formal/academic tone
- **Tone**: Technical but approachable — the reader is a developer who is comfortable
  with both English and Japanese

## Sentence Structure

- Prefer natural Japanese word order (SOV) over calque translations
- Break long English sentences into shorter Japanese sentences when it improves clarity
- For "why" explanations (the core of literate config), prioritize faithfulness to the
  original reasoning over brevity

### Good Example

```
English: "We use fish rather than zsh because its syntax highlighting works out of
the box without plugins."
Japanese: "zshではなくfishを使用しています。プラグインなしでシンタックスハイライトが
そのまま動作するためです。"
```

### Bad Example

```
Japanese: "fishはzshよりも使用します、なぜならそのシンタックスハイライティングは
箱から出してすぐにプラグインなしで動作するからです。"
(Too literal, unnatural word order, awkward phrasing)
```

## Org Markup Handling

### External Links

`[[url][description]]` — translate ONLY the description, keep URL intact:

```
English: [[https://nixos.org/manual/nix/stable/][the Nix manual]]
Japanese: [[https://nixos.org/manual/nix/stable/][Nixマニュアル]]
```

If the description is a proper noun (tool name, project name), keep it in English:

```
[[https://github.com/nix-community/home-manager][home-manager]]
→ no change needed
```

### Internal Links (Org Heading References)

`[[*heading][description]]` — the `*heading` part is a reference to a heading within
the document. When the target heading has been translated, the `*heading` part must
match the **translated** heading name. The description is translated independently.

```
English: See [[*MCP Servers][MCP Servers]] for details.
Japanese: 詳細は[[*MCPサーバー][MCP Servers]]を参照してください。
                  ^^^^^^^^^^^ must match the translated heading
```

```
English: (see [[*Outputs][packages]])
Japanese: （[[*出力][packages]]参照）
               ^^^^ "Outputs" heading was translated to "出力"
```

To get the correct translated heading name, check the corresponding `heading` entry
in `po/ja.po` for its msgstr.

### Inline Code and Verbatim

`=code=` and `~verbatim~` — preserve markers AND content exactly:

```
English: Use =nix flake update= to update inputs.
Japanese: =nix flake update= を使って入力を更新します。
```

### Bold and Italic

`*bold*` and `/italic/` — translate the text inside, keep the markers:

```
English: This is *important* because...
Japanese: これは*重要*です。なぜなら...
```

## Line Wrapping

- Match the line break structure of the msgid when possible
- Each PO continuation line should be roughly the same length
- Aim for ~76 bytes per line (Japanese characters are 3 bytes in UTF-8, so
  ~25 Japanese characters per line as a rough guide)
- Always end continuation lines with a space if the next line continues the sentence
  (matching English PO convention)

## Numbers and Units

- Keep Arabic numerals (1, 2, 3...), not Japanese numerals (一、二、三)
- Keep units in their original form: "16px", "256MB"
- Version numbers always in original form: "v0.74", "24.05"

## Punctuation

- Use Japanese punctuation: 。(period)、(comma)
- Exception: inside inline code/verbatim markers, keep original punctuation
- Parentheses: use full-width （） for Japanese text, half-width () around English
  terms/code within Japanese sentences

## Things to Preserve Exactly

- URLs
- File paths
- Package names
- Nix attribute paths (e.g., `programs.fish.enable`)
- Nix code fragments within prose
- Email addresses
- `\\\\` line breaks in PO entries
- PO escape sequences (`\"`, `\\n`)
