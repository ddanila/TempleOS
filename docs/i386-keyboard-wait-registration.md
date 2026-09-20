# Registered keyboard waits and retained input decoding

Blocking raw keyboard reads now publish a task-owned CI386TaskWait, with kind
I386_WAIT_KEYBOARD and the existing cancellation callback. A nested read rejects
an occupied task slot before consuming bytes. Direct cancellation and common
dispatch mark the same stack record. Repeated dispatch skips its resource;
normal success, failed blocking and cancellation clear the task slot on return.
The record remains live until then, protected by existing task lifecycle guards.

Cancellation does not consume bytes or alter status, loss counters, public task
flags, deadlines or IF. The raw read checks stack cancellation before touching
the input stream again. Tests free and poison that stream, or register a second
reader, before the cancelled task resumes. Decoded reads preserve partial scan
state and return no event when cancelled.

The bootstrap retains controller setup, IRQ byte collection, raw queue operations
and stream initialization. Raw task-context reading, scan decoding and decoded
reading now reside with the retained console and cancellation code. The console
initializes the reader against the already initialized kernel stream; controller
setup and IRQ unmasking follow. This avoids a kernel callback into separately
loaded cancellation code and makes room for further public-service integration.
Both the stream and retained code outlive every reader.

ConsoleRuntime version 11 replaces the configuration's read-function pointer
with the raw input pointer. Its service table remains 28 bytes and configuration
remains 28 bytes. It imports I386SchedBlock and I386KbcQueueGet in addition to its
previous imports. Version 10 is rejected before its callbacks run. Other module
versions and public/private task and input record layouts do not change.

This completes common registration for the currently implemented sleep, join,
ATA, message and raw-keyboard waits. It does not implement pending-break policy,
original Break delivery or cleanup of outer file/compiler references. Those are
still needed for the first usable original DolDoc editing session.

Validation passed both x64 rebuild generations, native input/message suites and
the full kernel boot/console/rejection suite. Kernel size is 362872 bytes, leaving
26248 bytes after the early stage; ConsoleRuntime retains 77816 bytes. See
[port progress](port-progress.md) for complete sizes, timings and scope.
