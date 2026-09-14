# Cooperative native tick sleeps

`Kernel/I386/Sleep.HH` and `Sleep.HC` provide a timer-driven wait queue for one
native scheduler. Initialize a zeroed queue once with `I386SleepInit(queue,s)`
and keep it and the scheduler live. The queue is serviced by calling
`I386SleepTick` once per delivered timer tick with IF clear, before IRQ EOI.

`I386SleepTicks(queue,ticks)` accepts nonnegative I64 tick counts. Zero returns
immediately; positive counts block the current non-root task. Root remains the
scheduler's idle context and cannot block here. The call masks interrupts from
registration through the block decision, and restores the original IF on return.
It allocates no heap memory: its waiter lives on the suspended task's stack.

Each tick decrements pending U64 counts. Due waiters are unlinked before their
sleep calls may return, and blocked tasks are made runnable without switching
inside the IRQ. Tick processing is linear in the number of sleepers. Counts
measure delivered ticks, not exact elapsed time or a delay measured from the
middle of a PIT period. Public millisecond conversion and sleep APIs remain work.

A generic scheduler wake can be spurious. Sleep rechecks its queued predicate
and blocks again until expiration. If a due task is already runnable from such
a wake, tick processing unlinks it without trying to wake it twice. The task,
stack and queue must remain live until completion. Forced cancellation/destruction
and nonlocal transfer out of a pending sleep are unsupported. This is a single-CPU
maskable-IRQ protocol, not an NMI/SMP-safe list. Invalid queue/task ownership during
a tick is reported as failure; earlier entries may already have advanced.

The combined task/exception fixture replaces catch-time tick polling with two-
and three-tick sleeps. Root idles when no worker is runnable; native PIT dispatch
wakes due workers. Tests inject an early wake once per lifecycle cycle, verify
that sleep does not return early, check IF-clear and IF-enabled callers, and
retain exception records, local values and FS/GS identity across each sleep.
Internal countdown checks cover values above 32 bits and expiration of an already
runnable task. Empty-queue and heap reclamation checks cover waiter lifetime.

The combined suite, general task and linked IRQ regressions, instruction audits
and both x86-64 rebuild/reboot generations pass. The combined image now exceeds
128 KiB and uses the existing 160 KiB loader capacity (0x10000–0x37FFF), below
its first arena at 0x40000. This is test-image capacity, not a full-OS RAM result.
