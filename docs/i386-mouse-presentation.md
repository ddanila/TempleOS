# Native mouse presentation and displayed backing

Native console/editor pointer show, move and hide operations now share the
graphics presentation lease. Moving a pointer restores the old rows and uploads
the new XOR image under one lease. The four backing planes are clean again
before release; there is no allocation or yield between XOR and restoration.

Before waiting, a request records the focused terminal's task number, the four
backing-plane identities and the displayed-image epoch. After acquisition it
revalidates the task, focus, live terminal, plane layout and epoch before touching
the backing. A canceled waiter owns no lease. A retired, superseded or stale
request returns without restoring rows from an obsolete image. Recursive calls
from a frame owner defer their pointer upload.

## Whole-image transitions

DisplayView.HC records the clean backing image after successful raw, graphics
or text-frame uploads. Its pointer values are identity keys; they do not retain
or dereference retired storage. Temporary text-frame buffers invalidate the
retained-image key before being freed. Graphics startup and terminal lifetime
validation remain separate responsibilities.

A raw console upload forces all sixty rows dirty when returning from a
different backing image. Updating only the result/prompt rows would leave the
rest of a graphics frame on screen. NativeTextBasePresent also rejects invalid
graphics readiness once graphics has started, rather than allocating an
unleased replacement image. The temporary-buffer path remains available before
graphics startup.

## Executable contracts

```
python3 tools/test-i386-mouse-present-wait.py IMAGE --out build/FRESH-mouse-wait
python3 tools/test-i386-doc-packed-sprite-editor.py IMAGE --mouse --out build/FRESH-sprite-mouse
```

The twenty-three-command contention fixture uses real PS/2 movement and a User
terminal while a managed graphics callback yields. It requires successful mouse
coordinate/packet reads, waits for a changed packet count and sixteen cooperative
turns, then checks the full terminal image with no premature pointer upload.
The old image paints the pointer through the held frame; its tip at (400,300)
is black where the independent oracle requires white.

Three cases exercise focus change after waiting, termination of the waiting
terminal, and frame completion without an intervening focus change. In the last
case a physical right-button packet releases the holder. Every pixel must then
remain blue, including rows a stale terminal pointer would have restored. A
focus hotkey returns to the root console. Each case checks mask 127, retirement,
exact parent heap and the root pointer. Further commands reject invalid text
readiness and return from both frame APIs without an explicit console restore.

The packed-sprite option moves the physical pointer over and away from the
original blue rectangle. Independent pixels check XOR colors and restoration
of its inclusive edges. This exposed an existing console-oracle DAC mismatch:
six yellow pointer pixels expected a channel value of 84, while the captured
image and the already-passing graphics-frame oracle use 87. The console oracle
now uses that same DAC expansion. Default black/white and solid-blue expectations
are unchanged. The harness also supports a uniform canvas color and a pointer
on return to the console.

## Current evidence

The corrected fixture fails the old image's held-frame pixel checkpoint
(`build/i386-c4-mouse-present-wait-red-final/result.json`). All twenty-three
commands pass on the current source image, with mask 127 in all three cases
(`build/i386-c4-mouse-present-wait-final/result.json`). The twelve-command packed
sprite/mouse session also passes every pixel observation
(`build/i386-c4-mouse-present-final-sprite/result.json`).

The existing forty-six-command mouse suite passes editor selection/dragging,
scroll/clipping, directory picking and help interactions; all sixteen
graphics/text-frame commands and their pixel checkpoints pass as well:
`build/i386-c4-mouse-present-final-mouse/result.json` and
`build/i386-c4-mouse-present-final-frames/result.json`.

All eighteen raw-contention commands and twenty-one stale-focus commands remain
green on the same source image, including their full-frame observations and
parent-heap checks: `build/i386-c4-mouse-present-final-raw/result.json` and
`build/i386-c4-mouse-present-final-focus/result.json`.

Bootstrap rebuild, cross-build and 386 boot audit pass. Startup passes at 8 MiB
in 48.46 seconds without build-provider loading
(`build/i386-c4-mouse-present-final-startup/result.json`).

## Remaining integration

These are the existing native fullscreen terminal/editor helpers. Original
window-manager cursor composition, full editor/view arbitration, debugger
transitions during a held frame, independent refresh-worker document/code
lifetime and the automatic A/B refresh gate remain open. This does not qualify
the original complete desktop, all cursor behavior, storage-owner termination
or C1–C5 completion.
