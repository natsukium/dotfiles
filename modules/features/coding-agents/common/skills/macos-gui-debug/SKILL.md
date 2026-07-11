---
name: macos-gui-debug
description: Verify a rendering or window-chrome change in any macOS GUI app unattended — find its CGWindowID via JXA, capture that window alone (with per-pixel alpha) using screencapture -l, and read exact RGBA via NSBitmapImageRep. Use for blur/opacity/corner-radius/glyph/color rendering bugs where a screenshot or pixel value is the ground truth. No Python and no Accessibility permission needed; for Linux/Wayland use wayland-gui-debug instead.
---

# macOS GUI debugging

Verify a rendering or window-chrome change by launching the app,
capturing **just its window**, and probing pixels. None of this needs
Accessibility permission. (System Events / keystroke injection *does*
need it and is usually blocked — don't plan on typing into the window
unattended.) Screen Recording permission is required for screenshots:
if `screencapture -x /tmp/full.png` produces a non-black image, you
have it.

Throughout, replace `MyApp` with the app's window-owner name (what
shows in the menu bar / Activity Monitor) and `myapp` with the process
name for `pkill -x`.

## Launch → window id → capture

```sh
./path/to/MyApp 2>/tmp/app.log & sleep 4   # or: open -a MyApp
WID=$(osascript -l JavaScript -e '
ObjC.import("CoreGraphics");
const list = ObjC.castRefToObject($.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly, $.kCGNullWindowID));
const arr = ObjC.deepUnwrap(list);
const w = arr.filter(x => x.kCGWindowOwnerName === "MyApp")[0];
w ? w.kCGWindowNumber : "none";')
screencapture -o -l$WID /tmp/app-win.png   # window only, no drop shadow
```

- `ObjC.castRefToObject` is required — `ObjC.deepUnwrap` on the raw
  `CFArrayRef` fails with "Ref has incompatible type".
- `screencapture -o -l<id>` captures the window's own composited
  content **with per-pixel alpha**: a translucent background shows its
  real alpha (e.g. 153 for `opacity = 0.6`), and rounded-corner pixels
  read fully transparent. This is the ground truth for transparency /
  corner-clip checks — a full-screen capture is not.
- A tiling WM (or the app itself) may resize the window after launch —
  re-read `kCGWindowBounds` instead of assuming a fixed size. The
  post-resize capture also catches relayout bugs (AppKit reorders
  sublayers on the first layout pass).

## Pixel probe — exact RGBA, no Python

```sh
osascript -l JavaScript -e '
ObjC.import("AppKit");
const rep = $.NSBitmapImageRep.imageRepWithContentsOfFile("/tmp/app-win.png");
function p(x,y){const c=rep.colorAtXY(x,y);return [c.redComponent,c.greenComponent,c.blueComponent,c.alphaComponent].map(v=>Math.round(v*255)).join(",");}
const h = rep.pixelsHigh*1, w = rep.pixelsWide*1;
JSON.stringify({w:w,h:h,center:p(Math.floor(w/2),Math.floor(h/2)),tl:p(2,2),bl:p(2,h-3),br:p(w-3,h-3)});'
```

- Corner pixels reading `0,0,0,0` = the rounded clip works.
- A frosted-glass / vibrancy background (`NSVisualEffectView`) behind a
  Metal/CALayer reads centre alpha `255` even when "transparent" —
  that's the opaque blur material, not a transparency failure. Test raw
  alpha with blur disabled.

## Process hygiene

- `pkill -x myapp` — match the **exact** process name. Never
  `pkill -f path/to/MyApp`, which also matches helper processes
  (renderers, daemons) whose argv contains that path and can kill
  unrelated user sessions.
- Comparing against an older build: use a separate build dir / git
  worktree so the two binaries don't clobber each other's artifacts.

## Multi-display gotchas

- `screencapture -x -R<x,y,w,h>` fails with "could not create image
  from rect" across display boundaries. Capture per display (`-D 1`,
  `-D 2`) or stick to window captures (`-l<id>`), which are
  display-agnostic.
