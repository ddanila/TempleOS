# Original logical mouse gain and edge history

The native pointer now uses the original default hardware gain, unbounded integer
prescale and grid-based edge-offset adjustment. The old native path applied unit
movement to a decoder already clipped to 640 by 480. Scaling that clipped result
would restrict reach. The corrected path follows original relative movement,
odd-count truncation, overshoot and reversal while retaining full logical reach.

The original arithmetic is extracted from MsHardSetPost into
Kernel/MouseHardPositionCore.HC. Prescale and hard position are CD3I64; hardware
scale is CD3. The classic caller retains its event/speed bookkeeping and invokes
the shared position/offset body. The native scheduled caller uses default scale
(0.5,0.5,1), then the existing logical MousePositionCore. Public ms.scale still
defaults to one; hardware gain and public logical scaling are distinct.

IRQ decoding remains integer-only, without allocation, callbacks or floating
point. The private observer retains unbounded prescale and queues each packet
without coalescing. Scheduled synchronization applies the original offset path
before coalescing logical UI motion. A separate per-slot position/presnap snapshot
preserves historical coordinates after later offset or grid changes. WinMgr uses
that snapshot directly instead of transforming hardware coordinates again.
The fixed queues retain their bounded loss/reset policy; arbitrary burst/loss
parity with the original hardware FIFO is not qualified.

The exported additional native MouseGet API retains its raw unit movement,
640-by-480 clipping, packet count and button contract. Its body and kernel bytes
are unchanged. Native terminal, document editor, directory picker, Help and
managed pointer presentation now query the internal logical getter. This keeps
hit testing and visible pointer coordinates on the same logical path.

## Original and native comparisons

```
python3 tools/test-i386-mouse-gain.py --out FRESH_ORIGINAL
python3 tools/test-i386-mouse-gain.py IMAGE --reference ORIGINAL --out FRESH_NATIVE
python3 tools/test-i386-mouse-raw-state.py IMAGE --out FRESH_RAW_API
```

The motion fixture sends identical physical deltas without feedback or synthetic
coordinate assignment. It records position, presnap, offset, text coordinates,
scale bits, grid state and buttons. The independent Python model uses original
integer prescale, binary64 half gain, truncating conversions, grid-based offset
adjustment and hard-event gating. The original compiler's ICFCvt emits FISTTP.

The first sixty-step original control matches that model. The old native image
finishes all sixty steps but differs at 59: its first (40,20) move yields
(360,260), versus original (340,250). The first native prototype had a host
export-prefix race and stopped before copying step 53; its failed receipt is
retained. The corrected observer waits for the complete following readiness or
completion line before reading exports.

The coverage audit then found the sequence's minimum x was three. Two exact
left-edge/reversal movements extend it to 62 steps and all four extents:
x=0/639 and y=0/479. The final original is `build/mouse-gain-original-v3`.
Its 744 state values match the independent model. Both `build/mouse-gain-native-fixed-v3` and
`build/mouse-gain-current-classic-v3` pass all 62 original records exactly. Earlier sixty-step native and
rebuilt-classic controls also match the original exactly.

A current-classic control caught an incorrect CD3 prescale pointer in the first
shared helper: the original type is CD3I64. Its structural runner receipt passed
bounds, but its independent comparison failed on zero coordinates. Both that
failure and the type-correct rebuilt-classic regression are preserved. No failed
or incomplete control is promoted to passing original parity.

## UI, raw API and resource controls

The host input helper now reads actual logical mouse state and gain, then steers
to the requested logical pixel. This preserves existing picker/Help screen
assertions under half gain. The mouse-state fixture retains mask 63 and uses
physical (16,24) for the final hard-position increment (8,12), followed by its
existing public-scale/grid oracle. The device group's pointer oracle expects
(332,248) after physical (24,16), while raw MouseGet still reports (344,256).

On the final image `build/i386-mouse-gain-cross-v3/kernel.img`:

- Help and file-picker select/double-click/editor/return workflows pass all their
  existing exact pixel checkpoints at 8 MiB, 486 without FPU and live WinMgr.
- The mouse-state behavior/pixel regression passes 63 at 8 MiB. Queue checks pass
  1023, retaining every old case and adding explicit noncoalesced reverse motion.
- Raw control callbacks still match the original eight-phase oracle. Five
  callback throw/Exit/owner-retirement modes pass 255 with exact heap recovery.
- Budget passes its unchanged mouse/save/cold-reopen/abort workflow (1023/63),
  exact reports/live identity/forms/menu/cursors/storage, 1886 preserved prior
  files and unchanged cold file tuples; both returns render fresh 42.
- The additional raw-state probe passes all six raw/logical movement/button
  snapshots and mask 15: NULL guards, IRQ preservation, restored document roles,
  exact heap recovery, unchanged file tuples and fresh 42.

The raw-state prototype used an unsupported local array initializer and failed
compilation; the corrected fixture computes the same expected button masks with
ordinary branches. The probe executes with a dedicated document and does not
assert typing commands while a button is held.

The complete legacy device group is still failing: after passing initial raw
state, motion and pointer pixels, held left-click changes the console typing
frame. The old image reproduces exactly the same failed typing bitmap. This is
an open console interaction, not a passing whole mouse-group claim. The first
wrapper left a running receipt after its terminal exception; its corrected
failure and exact correction/traceback hashes are retained separately.
The unflagged DocEd comparison retains its prior strict 113/95 state and 524/609
client-pixel failure; neither editor nor full desktop rendering is qualified.

The 8 MiB functional results report startup near 54 seconds under concurrent
runs. Their timeout/profile does not establish the separate isolated C5
60-second minimal startup gate, full resource recovery or native generations.

## Build and remaining acceptance

The final image pins 1859 delivered production sources and 26 build helpers.
Only ConsoleRuntime changes among sixteen modules; the native kernel remains
454392 bytes and ABI versions remain Compiler 104, Console 264 and Memory 41.
Both current classic bootstrap generations pass. The v2 and final v3 images are
byte-for-byte identical; v3 updates the pinned host pointer-oracle helper.
These classic rebuilds do not meet C5's two successive native generations.

`build/mouse-gain-audit-v1/audit.py` verifies source/module/ABI/bootstrap pins,
raw exports, arithmetic provenance, original/model/native comparisons, file
preservation and 744 rejected state corruptions, including matching per-step
export corruption so the independent expected values must reject each change. Qualification remains 2/686.
C1–C5 stay open, including full signed packet ranges and wheel/extended packet handling, complete ms_hard/MsSet
APIs, timing/speed and arbitrary scale settings, burst/loss behavior, raw/legacy
rendering and document input, custom hit/capture transitions, simultaneous UI
buttons, borders/menus, full pointer/frame parity, repeated-use resources,
remaining applications and native/minimal startup acceptance.
