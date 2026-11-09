# Raw-focus control input

Visible controls now receive physical button callbacks when managed rendering is
not admitted. Previously NativeWindowMousePump discarded the queued input in
that case. The original raw-mode eight-phase control contract passes, while the
unchanged old native image completes every phase and caller/heap mask 15 with
zero callbacks. The strict native test remains a failing before-control.

NativeWindowControlNeeded admits scheduled control input independently of
NativeWindowNeeded. It scans visible control owners, with no allocation or
yield, and also keeps an existing capture active through release. The control-only
route selects the first visible hit window, including one without a document
or controls, so a foreground window blocks controls behind it. It uses the same
control hit/callback/capture and owner-borrow paths as managed input. Raw-mode
recognition does not post document mouse messages or synthetic document keys.
Uncaptured retained legacy editor/help/picker scopes keep their existing input
route. Focus/legacy transitions during capture still need a dedicated comparison.

Managed graphics admission and the retained-surface presenter are unchanged.
This implements control input, not raw-control drawing or general raw-document
editing. No whole-window raster qualification follows from callback records.

## Matched raw and managed controls

```
python3 tools/test-i386-control-mouse.py --raw --out FRESH_ORIGINAL
python3 tools/test-i386-control-mouse.py IMAGE --raw --reference ORIGINAL --out FRESH_NATIVE
```

The same fixture accepts a Bool raw parameter, clears DISPLAYf_NOT_RAW when
requested, and exports both the request and actual input mode. The runner rejects
a mismatched reference mode. All existing button/drag inputs and callback,
coordinate, owner, IRQ, inhibition, child/caller/heap assertions remain intact.
The non-raw default still runs the original managed control contract.

The canonical raw original is `build/control-mouse-raw-original-v1`; the before
and fixed native controls are `build/control-mouse-raw-before-v1` and
`build/control-mouse-raw-fixed-v1`. The final image is
`build/i386-raw-control-cross-v1/kernel.img`. The fixed native run passes all eight
phases: ordinary left/right and border-relative coordinates, repeated stationary
and outside captured callbacks, outside release, and zero callbacks under self
or focus control inhibition. Every callback runs in WinMgr with enabled IRQs
and a live owner; caller roles, child drain and exact heap recovery pass. It
preserves every existing file tuple and renders fresh arithmetic 42.

Fresh managed controls `build/control-mouse-managed-original-v5` and
`build/raw-control-managed-regression-v1` also pass with the updated fixture in
its default mode. Counts of repeated held callbacks depend on scheduling and
hardware scaling; the oracle compares their sequence/coordinates and required
repetition, not an exact callback rate. The original hardware scale remains 0.5
and the native device still has unit gain; default motion-gain parity is open.

## Regression limits and provenance

The strict unflagged DocEd test in `build/raw-control-doced-regression-v1` retains
its exact existing failure: four active masks 113, return masks 95, expected
serialized text and client differences 524/609 in both sessions. It finishes
fresh 42, preserves existing files and retains its input hashes. This is evidence
against a new change in that declared client comparison, not a passing editor
or full-frame rendering claim.

All five callback-lifetime modes pass 255 in
`build/raw-control-lifetime-regression-v1`, including worker recovery/replacement,
frame progress, actual child reap, borrowed-control canary/detachment and exact
controller heap recovery. It preserves existing files and finishes fresh 42.
The unchanged Budget mouse/cold workflow passes 1023/63 in
`build/raw-control-budget-regression-v1`, including actual shutdown/cold boot
without Install/reseeding, exact reports/live/form/menu/cursor/storage state,
1885 preserved prior files, unchanged cold file tuples and fresh 42 after both
returns.

The build pins 1858 production sources and 26 helpers. Only WindowMouse.HC and
WindowMouseControls.HC change among production sources, and only ConsoleRuntime
changes among sixteen modules. The 454392-byte kernel, rendering-admission
source and public ABI versions 104/264/41 stay unchanged. Both classic bootstrap
generations and the 386 instruction audit pass; these are not C5 native rebuilds.
`build/raw-control-audit-v1/audit.py` rechecks raw exports, physical event
sequences, exact geometry/mode, source/build/module/file provenance and rejection
of 104 corrupted callback/edge/identity/IRQ/geometry/restoration/mode records.
The audit also recomputes the unchanged editor pixel differences from raw
screenshots and saved clients, and checks the unchanged original callback oracle
and mode-only fixture extension. The first identical relative movement from
(320,240), (-188,-134), settles at (226,173) originally and (132,106) natively;
`motion-gain-open.json` preserves this confirmed outstanding difference.

Qualification remains 2/686 and C1–C5 stay open. Remaining input work includes
raw/non-document rendering, document input on raw tasks, explicit legacy-scope
controls, custom hit callbacks, opaque-window overlap/capture transitions,
simultaneous buttons, wheel, border moving/resizing, menus, default hardware
motion gain and settled pointer/full-frame fidelity. Resource qualification,
normal editor/console input, remaining applications and native rebuild/minimal
startup acceptance are also open.
