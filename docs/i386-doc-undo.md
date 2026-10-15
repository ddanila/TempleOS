# Original document undo: reference and porting contract

The next compatibility slice is the complete `DocCaptureUndo` and
`DocUndoRestore` bodies in `Adam/DolDoc/DocFile.HC`, rather than an extension of
the retained native editor's separate undo path. C2/C4 remain incomplete.

## Reference evidence

`build/i386-c4-undo-first-reference/result.json` passes against the qualified
current x64 two-generation rebuild. All seven observed masks equal 63, with
unchanged pinned inputs. The shared fixture is
`tests/guest/i386-doc-undo-reference/Undo.HC`. Reproduce with:

```
python3 tools/test-i386-doc-undo-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-doc-undo.py build/i386-c2-doc-read-cross/kernel.img --out build/NEW-native
```

The clock case checks positive frequency metadata, nondecreasing reads,
progress relative to jiffies across Sleep, and preservation of the caller's
interrupt-enable state, including frequent reads with interrupts disabled.
Frequency agreement allows 20 percent plus 20 milliseconds of scheduling/read
slack; it is not a CPU-cycle precision claim. The six undo cases exercise
capture disabled, forced capture, a second forced snapshot, suppression with a
future last timestamp, capture with a deliberately old dirty snapshot, and an
incoming document lock. They assert exact restored text/cursor, timestamp range,
record ownership, flags, rings/count, caller document and heap recovery.

The native Console 105 control fails at the first GetTSC prerequisite with
`Invalid lval`; `build/i386-c2-undo-prerequisite-red/result.json` records the
failure and unchanged inputs. No native undo behavior has been tested yet.

These bounded observations do not qualify autosave, foreign document ownership,
allocation failure, cancellation/Exit, every serialized entry type, or the exact
boundary of the original dirty-snapshot timing expression. Add independent
contracts for those paths before broader compatibility claims.

## Required architecture

386 lacks RDTSC. Preserve the public timestamp/frequency relationship with a
software timestamp in PIT units, not an instruction that requires a newer CPU.
The existing private `NativeRandClock` is an entropy mixer and is not a
monotonic timestamp service; its source alias must not silently become undo's
clock.

The kernel timer counts delivered IRQs separately from millisecond jiffies.
Pass a private pointer to the actual IRQ tick counter alongside the PIT divisor;
using jiffies as interrupt counts would give the wrong frequency. Latch PIT
channel 0 under saved interrupt state and combine delivered ticks with its
within-period position. Reconcile observed modular counter movement so pending
IRQ delivery cannot move the result backwards. Publish the known PIT frequency
and preserve the caller's interrupt state. No public task/document layout change
is needed.

A software PIT service cannot reconstruct whole unobserved periods during a
long interrupt-disabled interval. Document that limit and test frequent polling
separately; monotonicity alone cannot prove elapsed-time accuracy. Avoid changing
the random entropy source as a side effect of exposing the new public clock.

Extract both original undo bodies unchanged into a shared include after their
clock, loader and serializer dependencies are available. Keep the retained
editor undo path until its integration is independently qualified. The original
body allocates records in the document heap but obtains serialized bodies from
DocSave; foreign-owner lifetimes require explicit tests rather than an assumed
ownership guarantee.

After the paired tests, run current-image serialization/loading and retained
keyboard undo regressions, plus the normal 8 MiB startup gate. Bootstrap,
cross-build, limited 386 audit and frozen source/build pins remain required.

## Console 106 candidate

The candidate adds three public exports (259 console exports total): GetTSC,
DocCaptureUndo and DocUndoRestore. `DocUndoCore.HC` is a byte-identical extraction
of both complete original functions and is included by both targets. The
console explicitly imports the kernel's existing cnts global; its loader now
provides 58 bindings. An initial cast/dereference macro failed the shared
parser's address requirement at member access and is not retained.

`TimeStampRuntime.HC` stores private last-count/last-value state under IRQ
exclusion. Each call takes the maximum of delivered-tick absolute time and the
previous timestamp plus observed modular PIT movement. The fixed frequency is
1,193,182 units/second (1,193 truncated kHz); initialization sets the initial
frequency and calibrated flag to describe this known PIT source. It does not
calibrate or expose CPU cycles. The private configuration gains the actual tick
pointer. Public task/document layouts and the console service table do not
change. Existing native editor undo remains separate.

Build/runtime qualification for this candidate must be read from the latest
PLAN.md checkpoint; source integration alone is not passing evidence.

The first Console 106 native run passes all ten commands at 64 MiB on
QEMU TCG `486,-fpu`: the API prerequisite, exact guest fixture readback, clock
mask 63, all six undo masks 63 and continued arithmetic. Inputs remain unchanged.
Evidence: `build/i386-c2-undo-contract/result.json`. The candidate cross-build is
`build/i386-c2-undo-qualified-cross`; it passes the limited loader instruction
audit (96 BIOS / 255 protected instructions), and all 1,489 source/build pins
match. Regression and current-source reference results remain separate gates.

The refreshed original control also passes all seven masks of 63 with unchanged
inputs in `build/i386-c4-undo-qualified-reference`. Current-image regressions
pass under `build/i386-c2-undo-`: save (21 commands), read (16), retained
keyboard undo (4) and normal 8 MiB startup (9 checks, 54.59 seconds, zero
build-provider loads). These results qualify this bounded integration; the
remaining failure/lifetime and full editor/application gates above stay open.
