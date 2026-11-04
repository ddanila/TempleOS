# Dictionary definition popup and default servant startup

The rebuilt original and native normal image pass an actual Ctrl+Shift+5
workflow from the Appl dictionary choices. ACDDef opens the Apple definition in
its real servant task and View. An independent decoder checks the complete
2,890-byte pinned definition record: all 33 fields and five definitions produce
exactly 2,878 bytes of displayed text. The canonical document also matches the
original at open, after physical Page Up and after physical Page Down.

Popup geometry is columns 1-78, rows 13-58. Cursor rows match 69 -> 24 -> 69;
task scroll state and the derived caret cell match too. Ownership, parent popup
link, focus, Put/Display identity and document window owner all pass. Actual
Escape retires the child and restores the parent's Put/Display/Border documents,
focus and unchanged unfinished input. Once the real parent choices refresh,
physical Ctrl+0 completes Applaud, and the submitted expression executes exactly
once with the correct argument and a fresh visible 42.

Final popup evidence:

- `build/i386-autocomplete-popup-reference-v7/result.json`.
- `build/i386-autocomplete-popup-native-v5/result.json`.
- Image: `build/i386-autocomplete-popup-cross-v3/kernel.img`.

The native profile is normal startup, 64 MiB, KVM, 486,-fpu and live WinMgr.
All eight persisted reports equal their guest-memory exports after QEMU closes,
and the final filesystem extent/bitmap audit passes. Harness and fixture source
snapshots and input digests accompany both runs; all final run inputs remained
unchanged. The observer does not invoke the completion or popup routines and
does not create the servant's documents.

Two production dependencies were missing. View's complete original body was
already resident as NativeOriginalView but lacked a public declaration/binding.
It is now published as View through _DOC_VIEW. ABI 210 has 583 bindings; the
preceding 582 names, setter order and nineteen-word data bitmap remain unchanged.
The new slot is a function. The build verifies the actual retained View export
and version (`publication-audit.json` beside the image).

Native startup also lacked the default HomeSys SrvStartUp hook. SrvCmdLine's
existing function/export lookup correctly did nothing when absent, leaving its
servant without display documents. The complete default body is now shared in
Adam/SrvStartUpCore.HC and included by HomeSys.HC and native StartOS. It calls
real DocTermNew, shows the window, raises it and updates visibility. This retains
the actual document/border/menu/scroll/right-click setup. Lookup/override and
missing-hook handling in SrvCmdLine are unchanged. Retention checks against the
pinned original prove the complete SrvStartUp and View bodies byte-identical;
expanding the HomeSys include restores the preceding full file exactly
(`original-retention.json`). This does not load all of HomeSys or qualify its
UserStartUp/StartUpTasks behavior.

Visible WinMgr documents now use the existing complete original DocKeyPageCore.
Previously only form documents reached it; the fallback moved 55 hard lines,
so Page Up reached row zero instead of original row 24 in this wrapped view.
The shared traversal uses the actual window height and original EdLineUp/Down
behavior. The native VGA editor and unattached ordinary documents retain their
existing path; other navigation keys are not promoted by this change.

Visual comparison accounts for actual desktop composition. Autocomplete can
cover the definition pane. A read-only final-screen observer preserves/calls the
previous callback and latches the actual rendered image and public visibility
map. Capture waits for two consecutive identical visibility maps and verifies
that the latched pane image has actually reached VGA before comparing it with
the original. This publication check uses the guest's own renderer image, not
the golden image, so it does not select frames for matching expected output.
The raster, frame record and z-buffer are copied while the VM is paused.

All 665,664 mutually visible static popup pixels match across the three stages.
Only cells actually covered by autocomplete are excluded; an unexpected
occluding window fails. The pointer is physically moved outside the pane. One
derived caret cell is excluded for blink phase, while its position is compared
as state. The complete document/text checks include content hidden by windows.
This does not qualify mouse-pointer appearance, caret blink rendering, the
changing autocomplete overlay or complete desktop appearance. The observer
restores the preceding final-screen callback when the popup closes.

Failed attempts remain distinguishable. The initial native baseline could not
compile the generated job because View was unpublished. Native v1, after its
publication, timed out because no default startup hook created a display doc.
Native v2 exposed the pointer/caret capture differences; v3 identified the real
Page Up defect. V4 had correct documents, paging and recovery but captured a
visibility map from a different publication phase than the raster. V5 uses the
frame latch and passes. Original v1 sent follow-up completion before ACTask
restored parent choices; subsequent runs explicitly observe that refresh.

Two original rebuild generations pass (`build/autocomplete-popup-rebuild-v3.log`),
as do the 386 instruction audit and the expanded 1,361-file delivered-source
audit. The audit now covers all packaged Kernel/Compiler/Adam/Doc source trees,
including root Adam files; its earlier selected-Adam-subdirectory scope omitted
the new startup core from verification even though the packager delivered it.
This remains a declared source scope, not full application/release qualification.

The separate 8 MiB KVM normal-startup smoke passes in 42.52 seconds with live
WinMgr/welcome, arithmetic, public input state/timing and exact framebuffer
checkpoints (`build/i386-autocomplete-popup-minimal8-v1`). The full servant
fixture is not qualified at 8 MiB: native-v1's stale welcome setup prevented any
commands; after correcting setup, native-v2 exhausts the heap compiling the
larger fixture before JRContract runs. Its recorded OutMem is not a servant
contract pass. Complete minimal regressions and resource qualification remain
open.

The startup-hook servant contract also passes against the original and on the
normal 64 MiB native image with live WinMgr:
`build/i386-default-servant-reference-v3/result.json` and
`build/i386-default-servant-preloaded-64-v2/result.json`. Mask 63 proves real
startup document/border/menu/right-click setup, inhibit-before-hook ordering,
exactly-once interposition while calling the default body, ten actual TaskExe
wake-master results of 42, completed flags, idle/title/ring recovery, hook
restoration and resumed console arithmetic. All framebuffer checkpoints match;
the final filesystem audit passes and the fixture bytes match exactly.

The servant harness retains keyboard transfer as its default setup. Its explicit
--preload-fixture option packages the identical source for focused service tests;
--ram-mib/--accel record the profile without changing the 8 MiB/TCG defaults.
Interposition needs the canonical Kernel/SymbolTypes.HH header; an initial 64 MiB
preload attempt stopped on that missing fixture dependency. The final 8 MiB
preloaded attempt exhausts allocation while loading the symbol header
(`build/i386-default-servant-preloaded-8-v2`), so preloading does not qualify the
8 MiB contract. The old long 64 MiB keyboard-transfer attempt was deliberately
interrupted during setup (interrupted.json); no service result is claimed for it.

Other definitions and slots, Shift-Escape, popup cancellation/fault paths,
complete key descriptions, numeric editor workflows, exact application heap
recovery, full Home customization and C1-C5 remain open. The earlier
[numeric](i386-autocomplete-numeric.md) and [editor](i386-autocomplete-editor.md)
records retain their own scope and image identities.

With the qualified original rebuild and word archive available, use fresh paths:

```sh
python3 tools/test-i386-autocomplete-popup.py --out build/ac-popup-original
python3 tools/test-i386-autocomplete-popup.py build/i386-autocomplete-popup-cross-v3/kernel.img --reference build/ac-popup-original --out build/ac-popup-native
python3 tools/test-i386-servant.py --original --startup-hook --out build/servant-original
python3 tools/test-i386-servant.py build/i386-autocomplete-popup-cross-v3/kernel.img --startup-hook --preload-fixture --ram-mib 64 --accel kvm --out build/servant-native64
```
