# Cooperative i386 context foundation

`Kernel/I386/Context.asm` switches between ring-0 stacks in the same flat address
space. Its native ABI is `U0 switch(CI386Context *old, CI386Context *next)`, with
two eight-byte HolyC argument slots. The current bootstrap passes its fixed NASM
entry address to native HolyC as a function pointer. It is not yet a relocatable
HolyC assembly module or the public TempleOS `Yield` implementation.

Call with IF clear, valid flat DS/ES, and exclusive ownership of both context
records and their live stacks. The routine saves EFLAGS, all general registers,
and DS/ES/FS/GS on the old stack, stores ESP in `old`, loads `next->esp`, restores
that saved state, and returns into the suspended caller. A same-context switch is
also supported. Suspended calls resume only when another context selects them.
The saved PUSHAD ESP slot is discarded by POPAD; it is not used to switch stacks.
The general-register order follows Intel's
[PUSHAD definition](https://pdos.csail.mit.edu/6.828/2008/readings/i386/PUSHA.htm).

## Initial stack

`I386ContextInit(context, stack, size, entry, arg, exit)` constructs an initial
frame without running it. The stack must be writable, eight-byte aligned, at
least 256 bytes, and sized in multiples of eight. Its end must fit a U32 address
and it cannot overlap the context record. Both function pointers are required.
Invalid arguments leave the context and stack unchanged; readable/writable pointer
validity and exclusive lifecycle ownership remain caller responsibilities.

The initializer reserves 88 bytes at the top of the stack:

| Byte offset | Contents |
| --- | --- |
| 0–12 | GS, FS, ES, DS, initially flat selector 16 |
| 16–44 | EDI, ESI, EBP, ignored saved ESP, EBX, EDX, ECX, EAX |
| 48 | EFLAGS, initially 2 (IF and DF clear) |
| 52 | Entry address consumed by the switch's RET |
| 56–68 | Dummy switch argument slots discarded by RET 16 |
| 72 | Task exit address, used when entry returns |
| 76–80 | The entry's full 64-bit argument |
| 84 | Spare zero word |

Entry has signature `U0 entry(I64 arg)`. Its ordinary RET 8 transfers to
`U0 exit()`, which **must never return**. The exit path must arrange retirement
and switch to a live context. Free a retired stack only from another stack after
it can no longer be selected; invalidating its saved ESP prevents accidental
reuse through a stale context record but is not reference tracking.

## Evidence and remaining integration

`python3 tools/test-i386.py --tasks` compiles the actual initializer and native
workers, allocates two guarded 8 KiB stacks from the native heap, and alternates
between workers for 64 yields each. It checks full-width entry arguments, stack
locals and arrays across suspension, 64-bit accumulators, progress ordering,
IF/DF, return-to-exit behavior, same-context switching, and rejected initialization.
After retirement it checks guards, frees both stacks, validates accounting, and
allocates the entire arena again. The context assembly is audited separately from
HolyC code and data.

This is a cooperative context primitive and a test scheduler on QEMU 486/8 MiB.
Public task creation and `Yield`, per-task FS/current-CPU GS
bindings, timer/input integration, public wait services, cancellation, debugger
state, exception unwinding, and software-F64 state still need integration. No
coprocessor state is saved. Stack guards in this test detect boundary writes after
execution; they do not provide a protected stack or recover from overflow. Physical
386 validation and the complete interactive OS remain pending.

## Initial native runnable queue

`Kernel/I386/Scheduler.HC` supplies a circular doubly linked runnable queue over
`CI386Task` records. `I386SchedInit` associates an initially zeroed scheduler and
root task with the context-switch function. Initialization requires exclusive
ownership; it does not capture the root's live stack until the first switch.
`I386SchedAdd` appends an unowned task with an initialized context before root.
The stack and entry/exit functions are still supplied by the caller.

`I386SchedYield` selects the next runnable task, updates `current`, and switches.
A one-task queue returns immediately. Queue operations save and restore the
caller's IF; switching itself happens with IF clear. Each resumed Yield restores
its own saved IF. Fresh entries begin with IF clear as specified by ContextInit.
Except for Wake below, these APIs are for cooperative task code, never IRQ/NMI callbacks, and callers
must not yield while holding a resource or critical section that another task
needs. Records and links must remain intact and exclusively managed by this API.

`I386SchedFinish` rejects attempts to finish root. Otherwise it unlinks the current
task, marks it finished, and switches to its successor without returning. The
owner association remains until another task calls `I386SchedReap`, which rejects
live/current/unowned tasks, clears the saved ESP, and releases the owner association.
The caller can then free the stack and reinitialize the record for another entry.
Finished tasks cannot be appended again before reaping and ContextInit. There is
no automatic stack release, cancellation, reference tracking, blocked-task queue,
or protection against stale external pointers.

The task test now additionally schedules two workers through this production queue
for 64 yields each, verifies round-robin progress and current-task identity, and
runs their normal returns through Finish. It checks the root-only queue afterward,
reaps/frees both stacks, then repeats with the same records. Rejected lifecycle
operations are checked before and after retirement. This still uses an explicit
scheduler pointer; FS/GS task bindings and the public TempleOS task API remain
future integration work.

## Blocking and wakeup

`I386SchedBlock(s)` removes the current task from the runnable queue, marks it
blocked, and switches to its successor. Root cannot block, so a runnable root
always remains. The suspended Block returns true only after Wake has reinserted
that task and a later cooperative yield selects it. Its own saved IF is restored.
Blocked tasks retain their stack and owner association and cannot be reaped.
There is no separate enumerable blocked-task list yet; event owners keep the
records they need to wake.

`I386SchedWake(s, task)` appends an owned, blocked, unfinished task before root.
It returns false for an already runnable, finished, unowned, or invalid task.
Wake masks interrupts only while updating the queue and restores the prior IF.
It may run from a maskable IRQ callback, but it never switches or preempts; NMI
use remains unsupported. The combined hardware/task test below exercises this path with PIT IRQ0.

Wake is not a counted event or a stored wake token. To avoid a missed wakeup when
an interrupt owns the condition, the waiter must mask interrupts **before**
checking that condition, recheck it after every return from Block, and restore
the original IF after the condition holds:

```c
flags=I386IrqSave;
while (!condition) I386SchedBlock(s);
I386IrqRestore(flags);
```

The producer records the condition before calling Wake. Another runnable task
must allow interrupts for interrupt-driven progress; the idle operation below can wait for interrupts, but fresh task entries still
start with IF clear. Blocking while holding
other resources needed by the producer can still deadlock.

The native test blocks both workers before any progress, verifies that only root
is runnable, rejects reaping blocked tasks, wakes worker 2 followed by worker 1,
and checks observed resume order 21. Duplicate wakes and wakes after completion
are rejected. Workers then complete the existing 64-yield lifecycle, and the whole
sequence repeats after retirement and record reuse.

## Hardware IRQ wakeup evidence

The task runner now also installs the production IRQ/exception entries. After the
queue lifecycle tests, a fresh worker starts with PIC lines masked, enables IF,
and blocks on an event counter using the interrupt-masked condition-check loop.
Root then unmasks PIT IRQ0 and enables interrupts. The callback publishes the
counter before waking a blocked worker and verifies that Wake neither changes the
current task nor enables IF inside the callback. Root yields cooperatively until
the worker completes 16 event waits and returns through Finish.

The worker checks a full-width stack value, current-task identity, and restored
IF after each wait. Root checks successful wakeup, task completion, stack guards,
reaping, and heap accounting. This passes on QEMU 486/8 MiB alongside the original
context and lifecycle phases. It validates event/queue integration; it does not
establish timing accuracy, a counted-event API, or a complete production kernel loop.

The task fixture now loads a 128 KiB stage (256 CHS sectors) to accommodate the
combined native test image. Its fixed heap at 0x40000 and stack at 0x90000 remain
outside that stage. The runner audits context, idle, IRQ, exception, and test IDT code
as separate executable ranges in `irq-assembly.txt`, excluding descriptor tables.

## Interrupt-driven idle

`Kernel/I386/Idle.asm` provides a four-instruction `U0 idle()` primitive:
STI, HLT, CLI, RET. Call it with IF clear after checking that there is no runnable
work, and with an installed, unmasked interrupt source capable of waking the CPU.
The [386 STI interrupt shadow](https://pdos.csail.mit.edu/6.828/2008/readings/i386/STI.htm)
covers the immediately following HLT, so a pending maskable interrupt cannot be
handled between enabling interrupts and entering the halt. After wakeup the
primitive returns with IF clear. The bootstrap currently links it with NASM.

`I386SchedIdle(s, idle)` masks interrupts, verifies that the caller is root and
root is the only runnable task, invokes the primitive, then restores the caller's
original IF. It returns false without halting for invalid arguments, a non-root
caller, or queued work. True means the idle primitive returned; it does not promise
that the interrupt made a worker runnable. Root must recheck the queue and yield
as appropriate. There is no timeout if the caller provides no usable interrupt
source, and idle is not allowed inside IRQ/NMI handlers.

The PIT/task test forces an initial idle with IF clear and a blocked worker,
verifies IRQ wakeup and restored disabled IF, rejects idle while that worker is
runnable, then runs the remaining event waits with an idle/yield root loop entered
with IF enabled. It also rejects idle from the worker and with missing arguments.
The idle assembly has its own instruction-audit range. This establishes the
primitive and scheduler integration, not a complete boot/task/device service loop.

## Native Fs/Gs compiler access

The i386 backend now supports the existing `Fs()` and `Gs()` intrinsics. Each
loads the 32-bit flat self-address pointer at offset zero through the corresponding
segment override and zero-extends it into HolyC's eight-byte value slot. This
matches the self-pointer convention used by the existing CTask and CCPU records;
it does not read a descriptor base directly or return the selector value.

For i386, the early optimizer leaves subsequent field accesses as ordinary
pointer arithmetic and loads/stores instead of folding them into the x64-oriented
MOV_FS/MOV_GS intermediate operations. Numeric fields retain their declared widths,
including eight-byte I64 values. The x64 optimization path is unchanged.

The task fixture temporarily installs two additional GDT descriptors, with FS
based at 0x50000 and GS at 0x50100, initializes separate self-addressed records,
and checks direct pointers, pointer fields, scalar/array reads and writes, and
64-bit arithmetic through Fs/Gs. It restores the previous GDTR and FS/GS selectors
before continuing the task lifecycle tests. These records lie outside the fixed
heap, loaded stage, and stack. The test-only descriptor setup code is a sixth
separate instruction-audit range; the GDT and GDTR data are excluded.

This verifies native compiler access through real protected-mode segments.
Production task/CPU record layouts, descriptor allocation and reloads during
context switches, and automatic scheduler bindings still need implementation.
