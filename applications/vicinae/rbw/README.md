# rbw extension for Vicinae

A keyboard-driven credential picker backed by [rbw](https://github.com/doy/rbw),
the unofficial Bitwarden CLI. This is the Vicinae equivalent of the
[rofi-rbw](https://github.com/fdw/rofi-rbw) setup used with fuzzel: search the
vault, drill into an entry, and copy or paste any of its fields.

## Why a custom extension

The official Raycast **Bitwarden** extension drives the official `bw` CLI with an
API key and its own session unlock, so it would not reuse the running
`rbw-agent`. Keeping rbw means shelling out to it directly, which a small
extension does cleanly while still giving the searchable list UI a script command
cannot. The action model mirrors the upstream `pass` extension: an entry list, a
per-entry field list, and Paste/Copy actions with the default chosen in
preferences.

## How it works

- `rbw list --raw` builds the entry list (this also unlocks via the agent).
- `rbw get --raw <id>` decrypts the selected entry; fields are addressed by UUID
  so colliding names stay unambiguous.
- `rbw code <id>` generates a fresh TOTP at the moment it is acted on, rather than
  storing the seed.

No secrets are persisted by the extension; unlocking is left entirely to
`rbw-agent` and its pinentry.

## Preferences

- **Default Action** — Paste (default) or Copy when pressing Enter on a field.
- **Additional PATH Entries** — colon-separated paths prepended to `PATH`. Vicinae
  is started from launchd/systemd, whose environment may not include the profile
  directory holding `rbw`/`rbw-agent`; set this if entries fail to load with a
  "command not found" style error.

## Development

```sh
npm install
npm run dev    # vici develop, hot-reloads into the running Vicinae
npm run build  # vici build
```

Packaged for Nix via `mkVicinaeExtension` in `../default.nix`.
