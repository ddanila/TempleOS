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
bindings, timer/input integration, blocking and wakeups, cancellation, debugger
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
These APIs are for cooperative task code, never IRQ/NMI callbacks, and callers
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
