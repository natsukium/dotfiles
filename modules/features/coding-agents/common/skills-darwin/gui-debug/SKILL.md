---
name: gui-debug
description: Verify a rendering or window-chrome change in any macOS GUI app unattended — find its CGWindowID via JXA, capture that window alone (with per-pixel alpha) using screencapture -l, read exact RGBA via NSBitmapImageRep, and synthesize keystrokes, chords, clicks and drags with CGEventPost. Use for blur/opacity/corner-radius/glyph/color rendering bugs where a screenshot or pixel value is the ground truth, and for driving keyboard or mouse behavior into the window. No Python needed.
---

# macOS GUI debugging

Verify a rendering or window-chrome change by launching the app,
capturing **just its window**, and probing pixels. Screen Recording
permission is required for screenshots: if `screencapture -x
/tmp/full.png` produces a non-black image, you have it. Input goes
through `CGEventPost` from JXA, not System Events, whose keystroke
injection is blocked without an Accessibility grant.

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

## Keyboard input

```js
// osascript -l JavaScript key.js <pid> <keycode> [flags]
ObjC.import("CoreGraphics");
ObjC.import("AppKit");
function run(argv) {
  const pid = parseInt(argv[0], 10);
  const app = $.NSRunningApplication.runningApplicationWithProcessIdentifier(pid);
  if (!app.isNil()) app.activateWithOptions($.NSApplicationActivateIgnoringOtherApps);
  delay(1.5); // let focus and the WM settle
  const src = $.CGEventSourceCreate(1); // kCGEventSourceStateHIDSystemState
  const down = $.CGEventCreateKeyboardEvent(src, parseInt(argv[1], 10), true);
  const up = $.CGEventCreateKeyboardEvent(src, parseInt(argv[1], 10), false);
  const flags = argv[2] ? parseInt(argv[2], 10) : 0;
  if (flags) {
    $.CGEventSetFlags(down, flags);
    $.CGEventSetFlags(up, flags);
  }
  $.CGEventPostToPid(pid, down);
  delay(0.12);
  $.CGEventPostToPid(pid, up);
}
```

- Prefer `CGEventPostToPid` over the tap-wide `CGEventPost(0, …)`: a
  mistimed tap post lands in whatever window the WM focused.
- Flag masks: shift `0x20000`, control `0x40000`, option `0x80000`,
  command `0x100000`. OR them for a chord: `ctrl+shift+h` is keycode 4
  with 393216.
- Keycodes are ANSI key positions, not characters: `h` 4, `c` 8, `d` 2,
  `x` 7, PageUp 116.

## Mouse gestures

```js
// osascript -l JavaScript click.js <pid> <fracX> <fracY>
ObjC.import("CoreGraphics");
ObjC.import("AppKit");
function run(argv) {
  const pid = parseInt(argv[0], 10);
  const app = $.NSRunningApplication.runningApplicationWithProcessIdentifier(pid);
  if (!app.isNil()) app.activateWithOptions($.NSApplicationActivateIgnoringOtherApps);
  delay(1.5);
  const list = ObjC.castRefToObject(
    $.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly, $.kCGNullWindowID),
  );
  const b = ObjC.deepUnwrap(list).filter(
    (w) => w.kCGWindowOwnerPID === pid && w.kCGWindowLayer === 0,
  )[0].kCGWindowBounds;
  const at = (rx, ry) => ({ x: b.X + b.Width * rx, y: b.Y + b.Height * ry });
  const src = $.CGEventSourceCreate(1);
  const post = (type, p) => {
    $.CGEventPost(0, $.CGEventCreateMouseEvent(src, type, $.CGPointMake(p.x, p.y), 0));
    delay(0.15);
  };
  // types: 1 down, 2 up, 5 moved, 6 dragged
  const p0 = at(parseFloat(argv[1]), parseFloat(argv[2]));
  post(5, p0);
  post(1, p0);
  post(2, p0);
}
```

- Read the window bounds **after** activating. A tiling WM moves the
  window on focus, so a click computed from stale coordinates lands on
  another app. Stop the WM for anything multi-step.
- Address the window by fractions of `kCGWindowBounds`, not absolute
  pixels.
- Step a drag through several `dragged` (6) events. A single jump to the
  end point skips the intermediate positions an app needs to turn a
  click into a drag.
- If events silently do nothing, check Accessibility for the terminal
  running `osascript`.

## Catching an animation mid-flight

A capture takes ~200 ms to set up, so a one-shot animation is over
before `screencapture` runs. Make the trigger repeat faster than the
effect decays, and any capture moment shows it.

To prove the opposite, that the animation ends and the app goes idle,
read `ps -o pcpu= -p <pid>` over several seconds and expect `0.0`.
`ps -o time=` needs an entitlement on current macOS and fails.

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
