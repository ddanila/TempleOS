# Canonical console transcript foundation

Faithful GetStr depends on the task's DolDoc input/output document and prompt
boundaries. Previously, the main console had no DocPut document; keyboard input
was assembled in a separate line buffer, and ordinary output only changed the
planar text surface. Child terminals had documents, but those documents did not
record their command sessions.

## Ownership and command source

Each managed terminal now owns a CDoc, including the main console. Its task's
put/display pointers select that document. Teardown clears matching pointers
and deletes only the owned document. Fixed DolDoc policy tables are initialized
before source startup, so plain command entry does not depend on successful
startup dictionary installation. Full dictionary setup remains in DocInit.

The terminal seeds its heading once, then records ordinary printed text, scalar
answers and typed input. A DOCT_PMT entry follows each visible prompt. Enter
extracts the source after that marker with DocScanLine; the compiler consumes
that allocation and the caller frees it after execution. The old resizable
input-line buffer is removed. Backspace and tab handling update canonical
entries while retaining the existing incremental VGA projection. Append typing
coalesces text instead of creating a separate entry for every key.

Literal output uses temporary plain-text flags with lock/flag restoration on
unwind. Emergency/raw diagnostics and full-screen viewer rendering remain
separate from this ordinary stream. No application-facing permission or test
mode is introduced. Console interface version is 71; the compiler interface
remains 70.

## Tests and qualification scope

`tools/test-i386-console-transcript.py` first fails against the previous image
because DocPut is absent (`build/i386-c2-console-transcript-red/result.json`).
The test checks shared put/display ownership, retained typed source, ordinary
printed/scalar lines, literal dollars in typed C source and real prompt entries through public
DocScanLine observations, alongside exact VGA output. It uses a writable copy
and verifies preserved input hashes.

The DocScanLine test has also been strengthened. Raw console source must use
single dollar delimiters for DolDoc commands; it does not pass through original
file-document unescaping. The older doubled delimiters could produce literal
text with the expected serialization, so byte comparison alone was insufficient
for positioning coverage. The test now requires actual DOCT_SHIFTED_X/Y entries
before checking their serialized values. All eighteen commands pass against the
pre-transcript image in `build/i386-c2-doc-scan-structural/result.json`.
The original-system reference fixture retains its file escaping and now also
asserts the two positioning entry types. All ten exported buffers pass in
`build/i386-c2-getstr-reference-structural/result.json`. This verifies the
original side independently instead of relying on its serialized text alone.

## Remaining integration

This is the canonical storage and command-entry step, not complete original
stdout/input parity. Structured Print/DolDoc presentation, CR/control rendering,
full transcript redraw/navigation, filter and keyboard semantics, entry replay,
and GetStr flags/default/cancellation/cleanup remain required. Viewer return
still uses its existing screen restoration; diagnostics can bypass the ordinary
transcript. Scrolling the framebuffer does not remove document history; measure
retained history and define resource policy during desktop qualification.

Next, connect public structured output and document-driven presentation without
losing ordinary command history. Preserve the original KDDocPutS /
DocPrintPartial / EdCharIns state machine, including partial dollar commands
across calls, user_put_s callbacks and flags; complete-command DocPutS calls
alone do not replace that behavior. Then add original/reference and native interaction
oracles before completing the DocGetKey/GetStr service. The six original GetStr
cases remain requirements, not substitutes for editing/replay/error workflows.

## Current evidence

Bootstrap self-rebuild and the cross-build/386 loader audits pass for console
interface 71. The nine-command 8 MiB startup/VGA gate passes in 42.2258 seconds
with zero build-provider loads (`build/i386-c2-transcript-checks/startup-8m`).
The corrected eighteen-command extraction test passes on this source candidate
as well (`build/i386-c2-transcript-checks/doc-scan-64m`).

The keyboard group passes all its framebuffer checkpoints, including 63 source
lines submitted through the canonical input path. The generic report's
`native_commands` counter covers submit-helper calls and is zero for this manual
hardware-event group; the actual input lines are recorded in debug.log. Evidence:
`build/i386-c2-transcript-checks/keyboard-64m/result.json`.

The initial transcript fixture also exercised the old unescaped-dollar stdout
behavior. That is an existing structured-output gap, not an acceptance contract
for original Print. The final fixture keeps dollar literals in C source, where
they must survive keyboard entry, compilation and history extraction. It does
not require unescaped dollars to remain literal once original output parsing
is connected.

The final thirteen-command transcript fixture passes with unchanged inputs:
`build/i386-c2-transcript-source-literals-v2/result.json`. An earlier attempt at
that revision was interrupted to correct host string quoting; it is not an
acceptance result.

## Open 8 MiB concurrency regression

The existing two-terminal background compile/edit/save session passes on the
previous image at 8 MiB (`build/i386-c2-background-previous-8m/result.json`).
The new source candidate passes it at the planned 64 MiB desktop profile
(`build/i386-c2-background-current-64m/result.json`), including continued
compilation during editing, exact VGA, persisted `work\x05`, retained value and
parent public-heap recovery. Both source images remain unchanged.

The same workflow **regresses at 8 MiB** on the new candidate. During editing,
a background parser allocation of `0x2233` bytes fails with raw-arena used
`0x653B38`, size `0x657200` and largest free payload `0x1820`. The host then times
out waiting for background compilation to advance after save. Evidence:
`build/i386-c2-transcript-checks/terminal-background/result.json` and its guest
log. The aggregate queue therefore reports failure; its other stages passing
does not override this result. This is not the already-restored nine-command
startup gate, which remains passing at 8 MiB.

The background runner now accepts an explicit `--ram-mib` selection and records
it; its default remains 8 MiB. The failing case remains open rather than being
removed or silently switched to a larger default. Inspect retained document/cache
backing and resident-code pressure before claiming preserved 8 MiB regression
coverage. Do not truncate history or remove graphics as a test workaround.
Full C1–C5 qualification remains open.

The [owned-capacity follow-up](i386-document-capacity.md) validates append/middle
reuse, growth and aligned-pointer safety, but does not close the 8 MiB
concurrency gap. Inspection identifies diagnostic routines in the resident
console as the next separation candidates; dependencies and loading/unloading
must be qualified before changing normal residency.
