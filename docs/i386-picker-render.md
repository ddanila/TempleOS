# Directory chooser frame diagnosis

The functional chooser checks pass, but the first native screenshots contain
overlapping text and border artifacts (see [chooser results](i386-pick-dir.md)).
Do not replace that open visual requirement with the returned-path assertions.
The frame probe separates document text, working pixels and persistent graphics.

Run the real FileMgr and all three original chooser cases with:

```sh
python3 tools/test-i386-pick-dir.py build/i386-win-cursor-pos-cross-v1/kernel.img --load-settings --observe-render --out build/picker-render-new
python3 tools/analyze-i386-picker-frame.py build/picker-render-new
```

The probe runs only for the first popup. Its final-screen callback copies 4,800
U32 text cells, 307,200 working pixels, 307,200 persistent-overlay pixels and
sixteen I64 state values from one completed drawing callback. It preserves any
previous final callback and restores that callback and the document's previous
full-refresh flag before the ordinary picker observer returns. Captured buffers
remain live through the host export interval. FileMgr itself stays byte-identical
to the original. This is explicit diagnostic instrumentation, not the normal
unobserved visual acceptance run.

The phases are initial capture, three extra ordinary presentations, and three
extra presentations with DOCF_DO_FULL_REFRESH set. The next manager frame
captures each phase. Other manager frames may run between phases, so the
recorded document-update count is authoritative rather than the requested
number of explicit presentations. The state order is viewport column/row,
document x/y, task scroll x/y/z, window left/right/top/bottom, document flags,
cursor column, text pan x/y and document updates_cnt.

The analyzer decodes both text cells and actual captured pixels into PNGs, emits
readable cell rows, and reports pixel differences for both blink states. It
currently requires zero global text pan, as in these captures. Its text-only
reconstruction is not a complete frame oracle: task drawing and controls also
draw pixels, and the original layering renders text cells before updating
windows. Difference counts alone cannot establish a renderer defect.

## Captured evidence (2026-11-07)

The first two-phase run, build/i386-pick-dir-render-v2, passes all three chooser
cases, masks 127/127/127, final arithmetic, filesystem validation and input pins.
All eight exported buffers have the expected sizes. The persistent overlay is
entirely transparent in both captures. Forced refresh produces clearer tree
rows but leaves graphics/border artifacts; that alone does not establish that
the flag caused the improvement. The earlier v1 diagnostic was deliberately
stopped after static inspection found a nonexistent probe field. Its cleanup
also failed to save a final screenshot; terminal-audit.json preserves that
cancellation. The runner now records interruption/cleanup failures reliably.

The added ordinary-frame control passes in
build/i386-pick-dir-render-control-v1, with all three chooser cases and unchanged
inputs. It ran a frozen diagnostic driver while v2 was still running. The
committed probe is byte-identical to that control; the committed driver differs
only in ROOT/probe paths (delivered-tool-parity.json). The two-phase inputs remain
reconstructible from their frozen runner and helper snapshots.

| Phase | Document update count | Document flags |
| --- | ---: | ---: |
| Initial | 2 | 4195840 |
| After ordinary frames | 11 | 4195840 |
| After forced-refresh frames | 20 | 6292992 |

The viewport remains (0,0) and window bounds remain (1,31,13,51). Ordinary and
forced-refresh text-cell captures differ in fifteen cells, all outside the
popup interior; the scrolling title changes. **No interior text cell differs.**
All three persistent-overlay buffers contain only transparent bytes. The
working-pixel captures retain graphics/border artifacts after both ordinary
and forced frames. Screenshots and layer-analysis.json preserve this evidence.

This rules out the persistent overlay for these captures and does not support a
forced-refresh workaround for the tree text. The initial screenshot also caught
a transitional frame with only two document updates. The remaining graphics
need isolation from text-cell composition, including actual window/control
geometry and drawing/occlusion behavior. Full chooser visual qualification,
FileMgr and C1–C5 remain open.

A focused original/native comparison now reproduces a separate border-coordinate
defect when synchronous frames run on an offset caller. See
[i386-window-border-context.md](i386-window-border-context.md) for the exact
4,800-cell contract and native baseline failure.

After the border-coordinate fix, build/i386-pick-dir-border-v2 passes all three
chooser cases. The analyzer now records popup_interior_differences for both
blink states and validates complete pixel-layer sizes and window bounds. The
historical ordinary/forced control and corrected frames both have zero interior
differences in their matching blink state; the border improvement is outside
that region. The old analysis is preserved as
layer-analysis-before-interior-metric.json, and all its preexisting metrics are unchanged. The initial frame
remains transitional. See the border-context document for completed rerun gates.
