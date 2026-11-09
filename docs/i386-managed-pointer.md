# Original pointer drawing in managed frames

The controlled MsgLoop probe isolates a missing managed mouse pointer. Before
this change, both Escape variants match the entire original saved document,
complete chronological message stream and restoration7, but differ in exactly
17 pixels at322,243..330,251. Those pixels form the original black arrow.
The failures remain at `msg-loop-frames-native-v2` and
`msg-loop-frames-shift-native-v2` on the ABI271 image.

The original DrawMs, DrawStdMs and DrawWaitMs bodies are now shared through
Adam/DrawMouseCore.HC and Adam/Gr/Draw{Std,Wait}MouseCore.HC. Expanding the new
includes reproduces the preceding Win.HC and GrComposites.HC bytes exactly.
Native managed frames use DrawMs in the final layer while holding the existing
presentation/render scope. This honors ms.show, actual installed hardware,
button colors and priority, the public pointer callback, and the open/closed
grab callback with its ordinary fallback. A custom final-screen callback
continues to replace the default final overlay. The default callback is
DrawStdMs. Public headers/export bindings expose all three original functions.

The previous post-upload solid pointer depended on the root console input
loop's visibility flag. It is removed from managed frames. Retained/raw
presentation remains on its existing path. The native hardware-state adapter
now exposes its actual installed bit alongside its existing timestamp. No
public mouse-state layout changes. Console ABI272 versions this cohort.

`tools/test-i386-msg-loop.py --frame-barriers` leaves the application and
independent18/19-message expectations unchanged. Its test document explicitly
requests DOCF_DO_FULL_REFRESH, and an observer waits for two actual document
and WinMgr updates after each observed phase. Key-down/up are separate phases;
the double-click batch retains its original timing. Wheel processing has its
own frame barrier without adding a public message. The observer never chooses
or moves the cursor. Full-screen comparison includes the pointer; no pixels or
saved-document entries are excluded, normalized or reordered.

Original full-refresh references repeat exactly for both document bytes and
all307200 pixels: `msg-loop-frames-original-v3/v4` and
`msg-loop-frames-shift-original-v3/v4`. Earlier two-frame-only references did
not force full refresh: normal repeated, but Shift varied only its hidden
cursor marker despite identical visible pixels. They remain evidence that
screen-update count alone does not control DolDoc's throttled full recalc.
Default-mode strict snapshot failures remain recorded separately; this focused
mode does not establish all default scheduling, desktop or resource behavior.

The direct pointer fixture covers12 cases on32x32 bitmaps: standard pointer,
wait pointer, no/left/right/both buttons, hidden pointer, null callback, custom
callback, open/closed grab and null-grab fallback. It records every pixel and
DC thickness/color/flags plus callback counts/arguments. The manager is paused
only during these direct calls; mouse/callback/grab state and suspension state
are restored before returning to the normal console.

Retained prototypes are not application evidence: the first observer helper
used an unresolved native forward reference; the first integration image
omitted three public export slots and rejected boot. Export-table size and
initialization bounds checks are corrected in the subsequent image. The first
direct probe used function-pointer declaration initializers rejected by the
original compiler itself; declarations and assignments are now separate.

The complete pen tables had not previously been initialized natively. The
standard pointer matched immediately, but the wait pointer exposed103 missing
thick-circle pixels. Native thick-point and small filled-circle entry paths now
ensure the complete original tables on first use, including all four64-pen
arrays and both circle-bound arrays. Allocations belong to Adam's persistent root,
not the caller. A render-scope guard serializes initialization and releases
partial published tables on failure or task cleanup; successful tables persist
as a shared cache. Thin-pointer startup does not allocate this cache. Failure
injection and all-resource cancellation qualification remain open.

The direct cache probe starts a child that first calls public GrFillCircle,
kills it, then checks every pen's dimensions, live non-child ownership and all
369152 bitmap bytes plus8192 bound bytes against an independent integer model
and the original. The first host model misread HolyC shift precedence in the
circle-center expression; the original counterexample is retained, and the
correct model centers at x-1-(i>>1). No actual bytes are rewritten.

The final candidate is `build/i386-managed-pointer-cross-v5/kernel.img` with
Console ABI272. Source-matching classic rebuilds and the386 audit pass; only
Kernel and ConsoleRuntime change from ABI271, and bare kernel remains458680
bytes. Final controlled MsgLoop tests `msg-loop-frames-native-v7` and
`msg-loop-frames-shift-native-v7` pass exact saved documents, complete streams,
restoration7, all614400 screen pixels, fresh42 and unchanged complete volumes.
All12 direct pointer cases pass at `draw-mouse-native-v4`, including the wait
pointer and DC state.

Stock User startup passes255 at8MiB (`managed-pointer-user-8m-v6`). Its
`--managed-pointer` option requires the calibrated17-pixel original arrow in
every managed welcome/command screen. The initial old oracle failed solely on
those17 extra pixels (with its normal cursor alternative); the explicit oracle
checks them rather than ignoring them. Existing retained-pointer expectations
remain available for older images and retained views.

Full default scheduling, original desktop orchestration, raw/retained pointer
parity, menus/grid/final-overlay integration, all callback lifetimes and native
self-host generations remain open. Inventory qualification remains2/686.

The final public GrFillCircle binding passes the child-cache probe at
`graphics-pens-native-v3` against `graphics-pens-original-v3`. Native tables are
absent before the child starts; the child invokes the public fill API, completes
initialization and is killed. Every pen remains valid with a live non-child
owner afterward. All256 pens,369152 bitmap bytes and8192 bound bytes match the
original and independent model, including dimensions. Fresh42 and unchanged
volume pass. The earlier native probe's missing-public-binding failure remains
at `graphics-pens-native-v1`; a provisional root-owner expression also failed
AOT compilation. The final code uses the already bound native Adam provider.

The retained editor regression passes614400 pixels and restores the original
User document roles at `managed-pointer-user-legacy-v3`; all1894 prior files
remain intact and fresh42 passes. Isolated normal8MiB KVM486,-fpu startup is
54.422s, with no other QEMU at invocation, exact welcome/42 pixels including the
original arrow and live WinMgr (`managed-pointer-startup-8m-v1`). This is only
the current60-second baseline subgate. The current source image pins1865 sources
and26 helpers; `build/msg-loop-frames-audit-v1/verify.py` rechecks those pins,
delivered fixtures, raw outputs, all pixels and original include expansion.

Both default-mode reruns remain strict saved-document failures at
`msg-loop-pointer-default-native-v1` and
`msg-loop-pointer-default-shift-native-v1`, with exact streams and restoration7.
Those runs used the preceding ABI272 checkpoint image. The controlled mode
supplements them and does not remove the unresolved scheduling requirement.


The subsequent ABI273 [constructor recovery](i386-dc-constructor-recovery.md)
checkpoint closes an unpublished-header leak during forced cancellation of pen
initialization. It preserves the complete pointer/MsgLoop/pen outputs here and
adds exact logical-heap and validated physical-backing recovery checks.
