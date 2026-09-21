# Original document entry lifetime on i386

ConsoleRuntime 16 retains the original DocEntryDel,
DocUndoDel, DocUndoCntSet, DocRemSoftNewLines, DocInsEntry, DocBinFindNum,
DocBinFindTag, DocBinsValidate and DocBinDel bodies. Original x64 and native
paths share the extracted source. Native lock adapters call the existing retained
document lock services. This integrates entry/binary lifetime and insertion;
full DocNew, DocRst and DocDel still require recalculation and editor callbacks.

The only changed reporting calls use DocReportLiteral for their fixed messages.
The x64 adapter calls original RawPrint. The native adapter writes directly to
the existing monochrome VGA text surface, bypassing document/input-filter paths,
then waits with interrupts masked by polling the existing PIT channel 0 counter.
It does not reprogram the PIT or require a TSC/387. It restores the prior IF,
raw/windowed display bit and input-filter bit and allocates no memory. Long raw
diagnostic pauses suppress normal IRQ delivery, as in original RawPrint. This
is a literal document-reporting boundary, not a complete native RawPrint or
StrPrintJoin formatting API.

Console configuration now carries the actual PIT divisor from the kernel;
version 16 validates it before initialization. Configuration size is 32 bytes;
the service record remains 32 bytes. The console additionally imports retained
StrCmp for original binary-tag lookup. Display-flag constants and the existing
PIT latch-read body are shared without changing their values or behavior.

The original/native lifetime corpus inserts a text entry, splits it around an
inserted newline, removes a soft newline, finds and validates a binary-backed
entry, deletes it with its owned storage, and counts/frees undo storage. It
checks cursor/queue state and returns public-heap usage to its initial value.
The native report corpus checks IF-on and IF-off calls, flag restoration and
no allocation growth. Invalid entry/binary deletion calls exercise visible
messages and their three-second pauses through the real retained functions.

Allocation/copy OutMem rollback is not established by these successful-lifetime
tests. The original copy/allocation bodies remain unchanged. The full native
editing-session acceptance still requires document construction, recalculation,
rendering, editor input, execution and save/reboot/reopen verification.

## Validation

Both x64 rebuild/reboot generations and the full QEMU/486 8 MiB suite pass.
Extracted lifecycle bodies match the previous original source except for the
literal reporting call names. The shared lifetime corpus returns eight on both
targets; native error/state checks pass with exact VGA output. Interactive
validation covers 184 commands / 247 lines, seven hardware breaks, eleven
lock commands and eight document-selection cases. Startup recovery and all 17
module rejection checks pass. All 1138 source hashes, nine build-input hashes
and both disk hashes match.

Normal startup measured 20.270 seconds and separate diagnostics 132.778 seconds.
ConsoleRuntime 16 retains 137464 bytes (137448-byte image). Kernel size is
364864 bytes, leaving 24256 bytes after the 4096-byte early stage in its reserved
393216-byte load area. These are QEMU/486 development results; strict 386 and
physical-machine validation remain open.
