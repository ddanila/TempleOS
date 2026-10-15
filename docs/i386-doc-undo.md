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
