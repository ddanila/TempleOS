# Original document renderer integration

The native console already compiles the original `DocRecalcCore.HC`, including
layout, text-cell writes and sprite handling. Console interface 79 exposes its
public DocRecalc entry point. This checkpoint does not replace the renderer or
switch standard output to the editor's separate drawing helper.

## Reference contract

```
python3 tools/test-i386-doc-render-reference.py --out build/FRESH-original
python3 tools/test-i386-doc-render-reference.py --current-system --out build/FRESH-control
python3 tools/test-i386-doc-render.py IMAGE --out build/FRESH-native
```

The test temporarily displays a new Render.DD document with a known default
attribute. It renders `A$FG,RED$B$FG$C`, a tab, D, newline and E with the original
TO_SCRN mode, then captures actual gr.text_base cells relative to the task's
window origin. The explicit ten-field signed-I64 expectation is:

```
1, 0xF041, 0xF442, 0xF043, 0xF044, 0xF045, 1, 1, 1, 0
```

These are successful recalculation; A, red B, reset C, tab-position D and
next-row E cells; adequate horizontal/vertical extents; released document lock;
and false for a null document. The fixture restores the prior display document
and task attribute. It does not present these cells to VGA.

The pinned-original result passes:
`build/i386-c1-doc-render-reference-final/result.json`. Before exposing the API,
the native compiler rejects the DocRecalc caller with Invalid lval at DocRecalc
(`build/i386-c4-doc-render-red/result.json`).

The rebuilt-original control and native public API also pass the exact ten-field
byte comparison (`build/i386-c4-doc-render-current-reference/result.json` and
`build/i386-c4-doc-render-native/result.json`). Native qualification uses ten
commands at 64 MiB on 486,-fpu. Bootstrap rebuild, cross-build and the 386 boot
audit pass (`build/i386-c4-doc-render-cross`). The new image passes 8 MiB startup
in 47.13 seconds with zero build-provider loads
(`build/i386-c4-doc-render-startup/result.json`).

## Framebuffer style oracle

```
python3 tools/test-i386-doc-render-style-reference.py --out build/FRESH-style-original
python3 tools/test-i386-doc-render-frame.py IMAGE --out build/FRESH-frame
python3 tools/test-i386-doc-render-frame.py IMAGE --ram-mib 8 --out build/FRESH-frame-8m
```

The original-style fixture extends the cell reference to 18 fields, checking
underline/inverse/blink flags and blue background. It passes at
`build/i386-c1-doc-render-style-reference-fixed/result.json`. Blink uses the
original BK command; an initial BL typo correctly failed the expected blink-bit
assertion and was corrected without changing that expectation.

The native frame fixture renders a new document through DocRecalc TO_SCRN,
presents its cells with NativeTextBasePresent, and pauses for physical QEMU key
events between two explicit blink phases. The host compares every pixel in the
640x480 frame against the checked-in original font and independently constructed
VGA palette. Expected rows, foreground/background cells and underline locations
are explicit in the test, independent of guest cell/output bytes. The fixture
then restores the prior display document, task text attribute and saved console
surface; arithmetic verifies return to the command loop.

An intermediate run matched both frames and returned to the console but failed
while serializing tuple-key color maps into JSON. The final harness converts
only the report representation to JSON-compatible values and pins the font hash;
guest behavior and pixel expectations are unchanged.

Final results pass at both 64 MiB and 8 MiB on 486,-fpu:
`build/i386-c4-doc-render-frame-final/result.json` and
`build/i386-c4-doc-render-frame-8m/result.json`. Each nine-command session checks
both full frames and console restoration. No OS implementation or normal boot
path changes were needed for these existing explicit APIs.

These are text presentation checks using an existing explicit presentation API.
They do not connect the normal stdout hook to this path or qualify sprite
composition, cursor navigation, scrolling, shifted glyphs or terminal focus.

## Next output integration work

1. Extend framebuffer qualification beyond the style cases above to offsets,
   wrapping, cursor and scrolling, with independent pixel expectations. Preserve each terminal's saved surface and focus behavior.
2. Resolve the shared renderer/compositor ordering. DocRecalc TO_SCRN both fills
   gr.text_base and draws sprites into gr.dc2. GraphicsFrameCore currently
   rasterizes cells before invoking its drawing callback. A bridge must retain
   both outputs and the original layering. Do not simply draw text over the
   completed sprite surface, discard sprites, or run document expressions twice
   to obtain a second pass. Keep temporary memory within the minimal profile.
3. Route the default string hook through DocPrintPartial and project the parsed
   document. Test split commands and dollar escapes through public stdout,
   callback consumption, foreground/background reset and error recovery. Keep
   typed command source literal and preserve its prompt boundaries.
4. Project DocPutKey edits and navigation from the same document, then continue
   the original DocGetStr2/GetStr path. Verify editing, filter input, entry replay,
   multiline/cancel/default behavior, interruption and persistent round trips.

The existing cell test is a renderer dependency check. It does not qualify VGA
presentation, sprites, cursor behavior, default stdout, GetStr or the whole
DocRecalc.HC inventory item.
