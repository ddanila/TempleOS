# Native task-flag eligibility

The native scheduler now skips tasks with either `TASKf_SUSPENDED` or
`TASKf_AWAITING_MSG` set, as well as privately blocked and finished tasks. The
original flag definitions are shared through `Kernel/TaskFlags.HH`, included by
the original KernelA and the shared task records. `CTask.task_flags` remains U32;
no record layout or module ABI changes are needed.

Yield, block and finish all use this eligibility rule while traversing the public
task list. If no task is eligible, selection executes adjacent STI/HLT/CLI and
rescans after an interrupt. The interrupt shadow prevents a lost wake between the
eligibility check and halt. The scheduler resumes selection with IRQs masked and
restores the caller's previous IF when yield/block returns.

Block removes private runnable membership before selection can enable interrupts.
An IRQ can therefore wake that same task safely, and selection may return to it
without a context switch. Finish removes both list memberships and wakes joiners
before selecting the successor. This lets a completed target make its joiners
eligible even when the root is suspended. Its allocation remains live until
another task reaps it, so an IRQ can safely run on the finishing task's stack.

The root's idle check now scans public eligibility rather than testing whether
the private runnable list is empty. Kernel loops use that check directly, so
suspended tasks do not force the root into a busy loop. Generic wake only clears
private blocking; it does not clear public suspension or awaiting-message flags.

## Verification

The task corpus covers both public bits independently, preservation of unrelated
bit 31, IRQ-driven root resumption with original IF both clear and set, idle with
privately runnable but publicly suspended workers, and a worker woken while its
own block operation is selecting a successor. It also covers all-ineligible yield
and finish paths, list detachment before an IRQ, stack guards and heap recovery.

Join tests suspend both joiners through target completion, verify that they still
prevent reaping, and resume them one at a time. A second join cycle suspends the
root: finishing the target must wake and run its joiners, which resume the root.
This specifically detects selecting a successor before waking joiners.

The expanded task runner needs a 256 KiB transfer ending at 0x50000; its temporary
heap moves to 0x60000. This changes only the test harness. Production bootstrap
reservation and the 8 MiB development profile remain unchanged.

Run the x64 rebuild, the native tasks, task-heaps, messages, except-tasks,
task-symbols and ata-tasks suites, then the full native kernel suite, as listed in
[task-ring verification](i386-public-task-ring.md).

## Remaining public scheduling work

This does not publish the complete public `Yield` interface. Wake-time eligibility
needs the original 1000-Hz jiffy contract; the current native PIT configuration
uses roughly 100 IRQs per second and its delivered-interrupt count cannot simply
be substituted for public jiffies. Public message-wait flag transitions, kill and
break delivery, device/waiter cancellation, single-user scheduling and debugger
context also require integration. The private message queue still uses its
existing block/wake protocol. Keep those contracts explicit when connecting the
original document-locking routines.
