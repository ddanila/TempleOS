# Original clipboard and document insertion

Console 102 compiles the complete original ClipDel, ClipCopy, ClipCut, ClipPaste,
DocCut, DocCopy and DocInsDoc bodies. They are shared with the original system
through DocClipboardCore.HC and DocInsertDocumentCore.HC; extracted bodies match
the previous original sources exactly. No clipboard branch is replaced with a
plain-text-only implementation.

Normal startup creates sys_clip_doc in the scheduler root's heap after DocInit.
Seven service exports plus this global bring console exports to 254. Public
task/document layouts, Memory 26 and private console services are unchanged.
The clipboard is shared between tasks rather than tied to an editor's heap.

## Contracts

The paired runners share `tests/guest/i386-clipboard-reference/Clipboard.HC`.
Six synchronous cases require mask 63: copy/paste into a text entry, cut/paste,
DocCopy/DocInsDoc at document end, DocCut, empty selection and incoming locks.
They check exact source/target/clipboard text, selected-entry flags, incoming
lock preservation and exact caller/clipboard-owner heap recovery after disposal.
The fixture obtains text entries from the live ring after DocTop/recalculation;
a saved DocPrint text-entry pointer can have been replaced during recalculation.

A seventh case copies from a real child task, waits for its exit and removal
from the parent's child ring, and reads the clipboard afterward. It checks root
ownership of the clipboard document, copied entry and tag using MHeapCtrl;
surviving text; and unchanged parent document roles. A warm-up precedes measured
worker lifecycles. A worker that creates/deletes the same source without copying
provides an allocation control.

The original reference requires the five portable worker observations (mask 31)
and records raw caller/Adam heap deltas separately. Adam's heap is shared across
original tasks; yielded worker sessions showed substantial changing deltas even
in control observations. Those aggregate counts do not establish a clipboard
leak or exact per-operation recovery. The synchronous original cases still
require their exact counters. Native acceptance remains stricter: worker mask 63
and four explicit zero-delta checks, for caller/root heaps in both the copying
and no-copy worker lifecycles. A leaked clipboard entry/tag therefore cannot be
hidden by the reference's allocation profile.

## Boundaries

These are normal-operation clipboard contracts, not complete DocPutKey/editor
compatibility. Data-field paste, filtered/soft-line content, binary/remalloc
entries, empty/reversed ranges, concurrent clipboard use, callback failure,
owner retirement and committed Exit still need focused coverage. Complete
source presence alone does not qualify those branches.

Original undo still needs complete DocLoad/serialization integration and a
386-compatible clock with a defined frequency; do not introduce RDTSC as a
386 prerequisite. The existing native editor undo remains separate. The full
original DocPutKey and actual chooser input gate remain open. See PLAN.md for
accepted build and test evidence.

## Accepted evidence

`build/i386-c4-clipboard-final-reference` passes portable masks
[63,63,63,63,63,63,31], with unchanged inputs and separate raw heap telemetry.
`build/i386-c2-clipboard-final-contract` passes all seven masks of 63 and four
zero-delta checks in fourteen commands, with exact fixture readback and unchanged
inputs. The tests run on writable copies of the base disk.

The original two-generation bootstrap and `build/i386-c2-clipboard-cross` pass,
including the limited 386 audit (96 BIOS / 255 protected instructions); all 1484
source/build pins match. Current-image character/form primitives, direct actions,
restoration exceptions and retained-child Exit regressions pass. Normal 8 MiB
startup passes nine checks in 54.98 seconds. These contracts do not close the
remaining editor/input or C1–C5 acceptance gates.
