# Native keyboard-read cancellation

`I386KbcInputCancel(input, task)` cancels a registered raw read, restoring private
runnable membership when necessary. It sets a borrowed Boolean on the waiting
stack and clears both input registration pointers with IRQs masked. Wake cannot
switch tasks. The resumed read checks its local flag before touching the input
again and returns FALSE without changing its data/status outputs.

Cancellation preserves queued raw bytes and their status, dropped-byte accounting,
all public task flags, wake deadlines and caller IF. A byte published before the
reader resumes does not finalize the read, so cancellation can still win and
leave that byte available. Invalid, foreign, finished and nonwaiting tasks fail.
Every successful or failed normal read also releases its borrowed stack pointer.

The decoded `I386KeyboardRead` wrapper propagates cancellation as zero without
changing its event output or accessing the stream again. Existing partial scan
state remains available for the next read, including an E0 prefix consumed
before blocking. Cancellation does not flush keystrokes or reset the decoder.

The kernel keeps its raw producer/reader. Cancellation code is linked separately
into retained ConsoleRuntime, whose ABI 9 service table appends
`cancel_read(task)` for the configured console input. Three existing kernel
exports supply IRQ save/restore and scheduler wake. This keeps the larger
cancellation implementation outside the constrained bootstrap image. The loader
validates all four service addresses and rejects ABI 8 before callbacks run.
CompilerProbe ABI 14 (72-byte configuration) borrows the loaded cancellation
callback only for its worker-phase diagnostic; normal boot does not run it.

Six native scenarios cover blocked and spuriously woken reads, byte publication
before cancellation, raw status preservation, suspension/message-bit/bit-31/wide
deadlines/IF, exact stream allocation reuse/overwrite, replacement-reader
isolation and continuation of decoded E0 input. Existing real keyboard IRQ,
controller setup, scan-state and message-broker tests also run. The input corpus
uses the existing 384-sector transfer profile below its test heap at 0x40000.
The loaded console callback is exercised with null and nonwaiting tasks by the
worker probe; queued cancellation is covered by the input corpus.

This completes another cancellation primitive, not public Break delivery.
A coordinated pending-break path still needs to identify a task's active wait,
respect break locking and active I/O, let file/compiler cleanup run, and deliver
the original exception/message/job/popup behavior. The console's ordinary
zero-result retry loop does not itself deliver a break.

Validation results are recorded in `port-progress.md` after execution.
