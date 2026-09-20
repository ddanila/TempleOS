# Native jiffy clock and task deadlines

The native PIT now credits a 1000-Hz-unit counter as well as counting delivered
IRQs. The original `CCntsGlbls` record and time constants are shared verbatim
through `Kernel/TimeTypes.HH`. The kernel owns one `cnts` instance, binds both the
timer and scheduler to `cnts.jiffies`, and publishes the same address for native
HolyC `extern CCntsGlbls cnts`. Other counters and calibration fields in the
record do not yet implement HPET, TSC or the original SysTimerRead contract.

## Accounting

The development platform retains its PIT divisor of 11932, about 100 IRQs per
second. Jiffies are time units, not the interrupt count. The nominal PIT clock is
1193182 Hz, matching [QEMU's PIT definition](https://raw.githubusercontent.com/qemu/qemu/master/include/hw/timer/i8254.h).
At initialization, integer division splits `divisor * JIFFY_FREQ` into whole
jiffies and a remainder. Each delivered IRQ credits the whole part, accumulates
the fraction and carries at most one extra jiffy. There is no division in the
IRQ update and no cumulative loss from rounding each interrupt separately.

After N delivered interrupts, the credited amount is
`floor(N * divisor * 1000 / 1193182)`. The old delivered-IRQ counter and private
tick-based sleep queue retain their units and behavior. Missed/coalesced IRQs
are not reconstructed: this is an interrupt-accounted clock, not a calibrated
wall clock. Deadline granularity remains the PIT interval plus cooperative
scheduling latency.

The borrowed counter must be distinct from the timer record and remain live
while its IRQ service can execute. Initialization resets it to zero. Scheduler
clock binding is allowed once on a fresh root before workers or context switches;
without a binding the scheduler uses time zero. Timer and scheduler reads/writes
occur with IRQs masked. A plain public I64 field read on 386 is not an atomic
snapshot across a low-word carry; callers needing one must preserve and mask IF
around the read. The scheduler already does so.

## Scheduling

Eligibility now also requires signed `wake_jiffy <= current_jiffies`, preserving
the original comparison and full I64 width. A zero or past deadline runs when the
other eligibility conditions permit. Neither private wake nor expiry clears the
deadline or overrides suspension/message waits. Root idle scans and successor
selection use the same rule; all-future selection halts until an IRQ advances
the counter or changes another eligibility condition.

The scheduler's borrowed clock pointer is appended to its private record; existing
member offsets and public task/CPU records are unchanged. The timer configuration
also gains private accounting fields. Runtime modules do not construct these
records or expose their sizes in a service table; their existing callable
interfaces and module versions are unchanged.

## Verification

The timer corpus compares six divisors, including minimum/maximum values, against
whole-interval integer arithmetic at each step; it checks longer fractional
accumulation, low-word carry, modulo-64-bit wrap and neighboring storage. The
scheduler corpus tests deadlines above 32 bits, signed past deadlines, root
expiry, suspension past expiry, a private wake before expiry, and a finishing task
waiting for the root's deadline, with stack guards and heap recovery.

Boot/worker JIT probes read the published counter, checking zero before IRQ
delivery and positive time afterward. The interactive suite reads JIFFY_FREQ and
the live counter. Run the x64 rebuild, native tasks/except-tasks plus the message,
task-heap, task-symbol and ATA-task suites, then the full kernel suite.

This supplies wake-time eligibility, not the complete public Yield/Sleep or break
contract. Original message/job/popup services, kill/break delivery and cancellation,
single-user scheduling and debugger context still require integration.
