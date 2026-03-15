# PO File Format Quick Reference

Quick reference for the gettext PO format as used by po4a in this project.

## Entry Structure

A PO entry consists of these parts in order:

```
#. type: paragraph              ← translator comment (po4a type info)
#: configuration.org:23         ← source reference (file:line)
#, no-wrap                      ← flags (optional)
msgid "English text"            ← original string (DO NOT MODIFY)
msgstr "翻訳テキスト"           ← translation (this is what you edit)
```

## Multi-line Strings

When text spans multiple lines, PO uses continuation syntax:

```
msgid ""
"First part of the text "
"continues on the next line "
"and ends here."
msgstr ""
"テキストの最初の部分"
"次の行に続き"
"ここで終わります。"
```

Key rules:
- The first line after `msgid`/`msgstr` is `""` (empty string)
- Each continuation line is a separate quoted string
- Trailing spaces inside quotes are significant (they join the lines)
- No trailing newline unless the original has one

## Flags (`#,` lines)

| Flag        | Meaning                                                    |
|-------------|------------------------------------------------------------|
| `no-wrap`   | Content must not be line-wrapped; msgstr is a single line  |
| `fuzzy`     | Translation is uncertain — needs review                    |

For `no-wrap` entries, the msgstr must be a single quoted string (no continuation lines):

```
#, no-wrap
msgid "Section Title"
msgstr "セクションタイトル"
```

## po4a Type Comments

The `#. type:` comment tells you what kind of Org element this entry comes from.
This is critical for classification:

| Type                        | Translate? | Notes                          |
|-----------------------------|------------|--------------------------------|
| `paragraph`                 | Yes        | Main prose content             |
| `heading *` to `*****`      | Yes        | Section headings               |
| `plain list -` / `+`        | Yes        | List items                     |
| `paragraph in QUOTE/quote`  | Yes        | Block quote content            |
| `paragraph in example`      | Yes        | Example block text             |
| `cell column N`             | Maybe      | Table cells (check content)    |
| `keyword title`             | Yes        | Document title                 |
| `paragraph in src`          | **No**     | Source code block              |
| `keyword NAME/name`         | **No**     | Source block identifier        |
| `keyword SETUPFILE`         | **No**     | Org setup file path            |
| `keyword PROPERTY`          | **No**     | Property drawer value          |
| `keyword OPTIONS`           | **No**     | Export options                  |
| `keyword STARTUP`           | **No**     | Startup keywords               |
| `keyword INCLUDE`           | **No**     | File include directive         |
| `property (*)`              | **No**     | Property values                |

## Source References (`#:` lines)

These show where the string appears in the source files:

```
#: configuration.org:23 .github/README.org:16
```

- An entry may appear in multiple files (shared content)
- The format is `filename:line-number`
- When shared across files, the translation must work in all contexts

## Obsolete Entries

Lines starting with `#~` are obsolete entries (removed from source but kept for reference):

```
#~ msgid "Old text"
#~ msgstr "古いテキスト"
```

Do not modify obsolete entries.

## Header Entry

The first entry in the file has an empty msgid and contains metadata:

```
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"PO-Revision-Date: 2026-03-01 14:13+0900\n"
...
```

Do not modify the header except for `PO-Revision-Date` and `Last-Translator` after
completing a translation batch.

## Validation

After editing, validate with:

```sh
msgfmt --check po/ja.po
```

This checks for syntax errors, format string mismatches, and other structural issues.
