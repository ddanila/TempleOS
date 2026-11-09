# Automatic terminal scroll controls

Original `DocTermNew` calls `WinScrollsInit(Fs)`. Native terminal creation used
`DocNew` directly and omitted those controls. Hidden scrollbars do not disable
their wheel callback: the original callback sets `WSSf_SET_TO_POS`, and document
recalculation can find a different insertion cursor even with
`DOCF_NO_SCROLL_BARS`. This affects later Print insertion, not message delivery.

`NativeTerminalCreate` now invokes the shared original initializer when it creates
its own document, for the root and new user terminals. A continuation retaining
an existing document retains its controls. Existing controls are reused. If
initialization throws, constructor cleanup detaches/frees only controls absent
before construction, alongside the unpublished document/surface/terminal.
The controls belong to the creating task's public data heap; existing owner
retirement detaches them before the task heap is reclaimed. Console ABI270
versions the changed startup behavior; other runtime ABIs and layouts are unchanged.

`tools/test-i386-terminal-scrolls.py` uses a pinned-original system and actual
QMP wheel input. A private displayed document hides its cursor and scrollbars;
the probe checks both default controls, owner/state/callback binding, wheel flag,
document position and exact caller heap/document restoration. The original
nine-value record is `1,1,1,1,5,2,0,1,1`. The prior native image gives
`0,0,0,0,0,3,0,1,1`, a strict failure. Explicit initialization on that same image
produces the original wheel/cursor/restoration values, followed by rendered42
and an unchanged volume. This diagnostic mode does not qualify automatic setup.

The optional lifecycle case creates three actual User terminals. Each must
already own exactly two correctly bound controls, reuse their identity without
allocating into the caller, retire through Kill, and restore the exact caller
data and code heap usage. The pinned original passes all twelve checks (4095).
Root scroll state is restored before the lifecycle measurement; task-local heap
addresses are not compared across architectures.

Evidence: `build/terminal-scroll-original-v3` (root),
`build/terminal-scroll-original-v4` (root and lifecycle),
`build/terminal-scroll-native-before-v2` (strict missing-default failure), and
`build/terminal-scroll-native-explicit-v1` (diagnostic repair).
The first prototypes used invalid HolyC aggregate initialization; both compiler
errors and the intentionally interrupted original run are retained, not runtime
qualifications. The corrected fixture copies `CWinScroll` with MemCpy.

Allocation-failure rollback, arbitrary control callbacks, other original terminal
constructor roles, full raster/input/desktop/resources and native self-hosting
remain unqualified. No additional inventory file or C1–C5 milestone is qualified
by this narrow contract.

The ABI270 candidate passes the same nine root values at
`build/terminal-scroll-native-v1` and all4095 lifecycle checks at
`build/terminal-scroll-lifecycle-native-v1`. Both also pass fresh rendered42 and
unchanged full-volume bytes/attributes/timestamps. The full image is
`build/i386-terminal-scrolls-cross-v1/kernel.img`, with1860 source and26 helper
pins, two source-matching classic bootstrap generations, and a386 instruction
audit. Only Kernel and ConsoleRuntime modules change from the quoted-source
image; the bare kernel stays458680 bytes. These are not C5 native generations.

`build/msg-loop-scroll-shift-native-v1` passes the unchanged Shift-Escape
workflow: exact original chronological stream, complete serialized document,
all19 records, restoration7, fresh42 and unchanged volume. Full original raster
equality is not asserted. The normal-Escape run at
`build/msg-loop-scroll-native-v1` matches the complete original18-record stream
and restores7, but still fails strict serialized-document equality. Its failure
precedes fresh42/unchanged-volume checks; neither is claimed for that run.
Original saved insertion order has previously varied, and this remaining case
needs investigation rather than record reordering or oracle relaxation.

A separate isolated normal8MiB KVM486,-fpu boot reaches live WinMgr and exact
welcome/42 pixels in53.763s (`build/terminal-scroll-startup-8m-v1`). This passes
only the current60-second baseline subgate, not completeC5. The audit under
`build/terminal-scroll-audit-v1` checks source/helper/bootstrap pins, exact
module changes, exported records and retained failures.
