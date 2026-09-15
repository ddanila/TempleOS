# Native public stack ownership

Native task stacks use the original shared `CTaskStk` record: `next_stk`, the wide
`stk_size` and `stk_ptr`, followed immediately by stack bytes at `&stk_base`.
The descriptor prefix is 20 bytes on i386. Its address is four-byte aligned so
that the following stack payload can be eight-byte aligned without changing the
public record layout.

`I386TaskSpawn` owns one allocation containing its task record, alignment padding,
the stack descriptor and requested stack payload, followed by the optional
private heap arena. The allocation remains live through task completion and is
freed by another task after successful reaping. Reaping clears `task->stk` with
the task identity. There is no separate stack allocation or duplicated private
stack-bound pair. The public stack size excludes the descriptor and private heap.

`I386TaskPlatformInit` reserves 24 bytes at the bottom of the caller-supplied boot
stack range. The descriptor begins four bytes into that reservation, and the
payload begins at byte 24. The existing 32768-byte boot reservation therefore
provides 32744 stack bytes. Validation checks that the current frame and stack
pointer remain above the descriptor before writing it. This static reservation
has kernel lifetime and is never returned to the heap.

Exception registration, dispatch and caller-frame walking use the public bounds.
A missing descriptor rejects registration or caller walking. `next_stk` and
`stk_ptr` start at zero, as in the original initial-stack contract. Native stack
growth and `CallStkGrow` are still absent, and the public saved-register fields
are not yet the scheduler's complete context-switch interface. This change does
not claim the full public task/debugger service contract.

The native backend now implements the original pointer-returning `GetRSP`
intrinsic by copying ESP to EAX and zeroing EDX. Startup exposes the original
signature. It reports the stack pointer at the evaluation site, including any
active expression temporaries; it does not synthesize the saved task context.

Removing private stack bounds changes later `CI386Task` field offsets. Module
interfaces therefore advance to CompilerRuntime 39/200, FileRuntime 17/32,
CompilerProbe 9/56 and ConsoleRuntime 5/20 (version/bytes).

Validation targets include task reuse, stack guards, frame walking across yields,
exception recovery and cleanup, boot-stack reservation, native source access to
both task phases, and console stack-pointer bounds. Test outcomes and measured
memory use are recorded in [port progress](port-progress.md).
