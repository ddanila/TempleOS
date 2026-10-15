# Automatic document refresh goal

Make displayed DolDoc documents update through the scheduled window manager,
including dynamic content and task drawing, without application calls to
DocRecalc or a graphics presentation helper. Preserve the original temporal
contract: existing text cells are composed before current document/sprite
updates. Normal stdout and original input/editor integration then use that
same document presentation path.

## Executable acceptance baseline

```
python3 tools/test-i386-doc-auto-refresh-reference.py --out build/FRESH-reference
python3 tools/test-i386-doc-auto-refresh-reference.py --current-system --out build/FRESH-control
python3 tools/test-i386-doc-auto-refresh.py IMAGE --out build/FRESH-native
```

The reference shows a full-window document whose tag changes from A to B. It
waits with original Refresh(3), then checks callback progress, text cells and
actual composed glyph pixels. The application does not call DocRecalc or a
presentation helper. Metadata is `[1,65,1,66]`; independent original-font pixels
match both glyphs. The fixture restores its document, attributes and geometry.
An initial fixture used nonexistent uppercase display-mask names; the corrected
fixture uses the original display-flag bit indices.

Pinned original and rebuilt-original controls pass:
`build/i386-c1-doc-auto-refresh-reference-flags/result.json` and
`build/i386-c4-doc-auto-refresh-control/result.json`. The native test fails to
show its initial A frame (`build/i386-c2-doc-auto-refresh-red/result.json`). Its
application only selects the document, changes the dynamic value and sleeps or
waits for keys; NativeTextBaseRestore appears only in teardown. This gate remains
open. Passing an explicit presentation test does not supersede it.

## Architectural work and gates

1. **Recoverable render scope.** Dynamic tag replacement must retain the old
   value until its callback succeeds. Release acquired locks, drawing aliases
   and local depth storage on exceptions. Test failure, unchanged retained tag,
   exact heap recovery, successful retry and normal original-renderer controls.
   The first concrete failure and fix are tracked in
   [renderer callback recovery](i386-doc-recalc-recovery.md). Continue with other
   callback/allocation sites. Native renderer cleanup now passes plain child,
   nested and User-terminal callback Exit cases. Draw/final and mixed document/
   frame exits now pass as well; see [graphics lifecycle](i386-graphics-exit.md).
   Yielding holders and competing managed graphics/text presenters now have a
   separate cancellation/interleaving gate in that lifecycle document. Continue
   with storage-owner termination and raw/editor display ownership.
   A terminal document owner's Exit/external kill while a linked child yields
   inside its owner-compiled tag now passes both lifecycle cases; see
   [owner-exit coverage](i386-render-owner-exit.md). This does not establish
   lifetime protection for an unrelated persistent worker or qualify a change
   to the original callback execution context.
2. **Worker/document lifetime and presentation ownership.** Use the native
   scheduler's established ownership model. Exit waits for linked children and
   inherited task/code/heap references defer retirement; reuse those guarantees
   rather than keeping unprotected task/document pointers. Cover owner exit,
   killed or yielding callbacks, document replacement/deletion and frame-lock
   release. Serialize shared graphics buffers with editor, raw and explicit
   graphics users; a transient competing refresh must not turn their current
   presentation failure path into KernelStop. Preserve terminal surfaces and
   focus. Bulk console/focus uploads now join the lease and revalidate terminal
   identity/focus after waiting; see [raw presentation](i386-raw-presentation.md).
   Native mouse overlays also join the lease, reject stale backing images and
   restore complete raw images on view changes; see
   [mouse presentation](i386-mouse-presentation.md). Original cursor composition,
   full editor/view ownership and debugger transitions during a held frame
   remain open. Validate the chosen lifecycle with end-to-end
   termination/recovery tests before enabling the worker at normal boot.
3. **Scheduled original window updates.** Integrate document, border, task
   drawing and controls with the refresh/compositor contract and measured
   cadence. Reconcile the existing sys_winmgr_task root proxy and public window
   order with the actual managed refresh task. Pass the automatic A/B gate,
   single dynamic evaluation per frame, focus/order and multi-terminal cases,
   callback failure recovery and frame/resource measurements. One live document
   is the first executable case, not the complete window-manager acceptance.
4. **Stdout and original document input.** Route default strings through
   DocPrintPartial, update the same displayed document, and preserve typed command
   source as literal text. Cover split markup/escapes, colors, prompt boundaries,
   scalars, key editing/navigation and raw transitions. Then integrate original
   DocGetStr2/GetStr, entry replay, cancellation/defaults/multiline input and
   persistence. Requalify minimal-profile regressions and full-profile behavior.

These steps advance C2/C4 and enable C3 applications. They do not replace the
C1–C5 acceptance requirements or qualify a reduced, opt-in presentation demo as
the complete desktop. Repeatable behavior remains automated; no manual-session
gate is introduced.
