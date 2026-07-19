---
name: gui-debug
description: Verify a rendering or window-chrome change in a GUI app unattended on Linux/Wayland under the niri compositor — enumerate windows and read output scale via niri msg --json, capture a specific window to a file with niri msg action screenshot-window --id, and probe exact pixel RGBA with ImageMagick. Use for layout/glyph/color/HiDPI rendering bugs where a screenshot or pixel value is the ground truth.
---

# Wayland (niri) GUI debugging

Verify a rendering change by launching the app, finding its window
through the compositor, capturing that window to a file, and probing
pixels. On Wayland there is no cross-client "capture window N" API —
capture goes through the **compositor**, and under niri that is the
`niri msg` IPC, which can target a window by id directly. No external
screenshot tool is needed.

`niri msg action` arguments evolve between versions — `niri msg action
screenshot-window --help` shows the flags your running niri actually
accepts.

ImageMagick (`magick`) and `jq` may not be on PATH. On Nix, run them
ad-hoc without installing:
`nix run nixpkgs#imagemagick -- magick ...`, `nix run nixpkgs#jq -- ...`.

## Find the window and the output scale

```sh
# windows: id, title, app_id, pid, focus, and logical window_size
niri msg --json windows | jq '.[] | {id, app_id, title, is_focused, size: .layout.window_size}'

# outputs: logical size/position and scale per monitor
niri msg --json outputs | jq 'to_entries[] | {output: .key, logical: .value.logical}'
```

- `layout.window_size` is in **logical** pixels; the screenshot PNG is in
  **physical** pixels — `physical = logical × scale`. A logical 960×600
  window on a `scale: 2.0` output captures as 1920×1200. Do this math
  before claiming a size regression.
- Use the window list to confirm the app actually mapped a window (and to
  grab its `id`) before capturing — a crash leaves an empty list, a
  clearer signal than a black frame.

## Capture a specific window

`screenshot-window` takes a window `--id` (no need to focus it) and a
`--path` (must be **absolute**); it writes the PNG there and also copies
to the clipboard.

```sh
WID=$(niri msg --json windows | jq '.[] | select(.app_id=="MyApp") | .id')
niri msg action screenshot-window --id "$WID" --path /tmp/win.png
# focused output instead of a single window:
niri msg action screenshot-screen --path /tmp/screen.png
```

- `--id` targets the window even when it isn't focused. If you need it
  focused for some other reason (e.g. it only renders when active),
  `niri msg action focus-window --id "$WID"` first.
- The pointer is excluded from `screenshot-window` by default
  (`--show-pointer` to include); `screenshot-screen` includes it by
  default (`--show-pointer false` to drop).
- The capture is the window's **composited** contents — it cannot by
  itself prove a window's own per-pixel alpha (that's a macOS
  `screencapture -l` strength, not Wayland's). Test transparency by
  compositing over a known solid backdrop and reading the blended result,
  or via the app's own rendering logs.

## Pixel probe — exact RGBA

```sh
# single pixel at (x,y), as "srgba(r,g,b,a)"
magick /tmp/win.png -format '%[pixel:p{120,80}]' info:

# dimensions + a few sample points
magick /tmp/win.png -format 'w=%w h=%h\n' info:

# average a region (coarse "is this the colour I expect" check)
magick /tmp/win.png -crop 20x20+100+100 +repage -resize 1x1 -format '%[pixel:p{0,0}]' info:
```

- Sample in **physical** pixels (the capture's own coordinates), not
  logical — account for the output scale from `niri msg outputs`.

## Process hygiene

- `pkill -x myapp` — match the **exact** process name. Never
  `pkill -f path/to/MyApp`, which also matches helper/renderer processes
  whose argv contains that path and can kill unrelated user sessions.
- Comparing against an older build: use a separate build dir / git
  worktree so the two binaries don't clobber each other's artifacts.

## When niri's own capture won't do

If you need a raw framebuffer grab outside niri's path (e.g. capturing a
layer-shell surface niri won't target, or a whole output region),
`grim` works: `nix run nixpkgs#grim -- -o <output> /tmp/out.png`.
`slurp`, `satty`, and `swappy` are interactive — they block on a human,
so don't use them in unattended runs; compute regions from `niri msg`
geometry instead.
