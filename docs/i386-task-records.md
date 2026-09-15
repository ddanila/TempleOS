# Shared public task and CPU records

`Kernel/KernelA.HH` now includes the original public records from four small
headers: `WindowScrollTypes.HH`, `JobCtrlTypes.HH`, `TaskTypes.HH` and
`CpuTypes.HH`. The headers retain all original task and CPU fields, including
window/document state, task links, exception/answer state, compiler controls,
callbacks, jobs, saved register values and user data. Callers provide the declared
pointer dependencies and include each definition once in their compilation
scope, as with `Kernel/Types.HH`.

The extraction preserves the complete x86-64 `CTask` layout: 1192 bytes and all
105 member entries, including both padding entries. The original metadata was
captured before extraction. `tests/fixtures/task-layout.json` records each member
as `[name, x64_offset, x64_size, i386_offset, i386_size, pointer_depth, count]`.
The i386 expectations shrink pointers and the four pointer fields embedded in
`CJobCtrl`; explicit integers, floating-point fields, arrays and other gaps retain
their widths. The task's final size is rounded up to an eight-byte boundary.

Two layout rules are explicit in the shared definitions:

- `CTaskDying.wake_jiffy` must match `CTask.wake_jiffy`. Its `last` pointer shares
  an eight-byte slot, making the offset 16 on x86-64 and 12 on i386. The original
  x86-64 pointer and wake offsets are unchanged.
- `CTask` and `CCPU` explicitly round their trailing size to eight bytes before
  the existing alignment assertions. This adds only target-required tail padding.

| Record | x86-64 bytes | i386 bytes checked by the native fixture |
| --- | --- | --- |
| `CTask` | 1192 | 992 |
| `CCPU` | 256 | 232 |
| `CJobCtrl` | 40 | 24 |
| `CWinScroll` | 32 | 32 |

The public register-image fields retain their original I64 widths and names on
both targets. They do not introduce 64-bit registers into the 386 execution
context. Architecture-specific switch/interrupt state remains in the native
context implementation.

`Kernel/I386/PublicTaskTypes.HH` supplies the declared pointer dependencies and
includes the shared records once per native compilation scope.
`CompilerTaskLayoutProbe.HC` uses these same definitions through the live scheduler.
It asserts all 103 unambiguous task member offsets against the captured layout contract, plus record sizes and
the dying-task overlap. Native boot and worker executions allocate the complete
records, round-trip self/CPU/task pointers and wide values, exercise a task drawing
callback, check an allocation guard, and reclaim the temporary records.

`tools/check-task-layout.py` boots the rebuilt x86-64 image, compares every task
member's name/order/offset/size/pointer shape with the original metadata, checks
supporting record sizes, and verifies that the native assertions match the
fixture. Run:

```sh
python3 tools/test-rebuild.py
python3 tools/check-task-layout.py
python3 tools/build-i386-kernel.py --test
```

## Live native records

`CI386Task` now inherits the complete 992-byte `CTask`; its private context begins
at offset 992. `CI386Cpu` inherits the complete 232-byte `CCPU`, followed by its
scheduler pointer. GDT segment bounds cover the extended records. Platform binding
sets the task's public `gs` pointer to the live CPU, whose public `num` is zero.
Scheduler initialization sets the public task signature, and reaping clears the
signature and CPU pointer with the task identity.

Exception values, caller traces, the hash table and active compiler-control links
now occupy their public fields, with no duplicate private copies. The public
`catch_except` is one byte and `except_rbp` remains eight bytes; exception capture
zero-extends the native frame address. Resident-declaration probes write the catch
flag through a native `Bool` declaration and check adjacent answer fields for
unintended writes. Boot and worker layout probes use typed private FS/GS getters
to compare the live public view with the scheduler and active compiler control.

The changed task offsets require new module versions even though service-table
sizes stay unchanged: CompilerRuntime 36/200, FileRuntime 14/32, CompilerProbe 6/56
and ConsoleRuntime 2/20 (version/bytes). Rejection fixtures substitute each previous
version to check that the loader rejects its interface before dependent callbacks
run. These are version-tag rejection tests, not execution tests of archived old
module binaries.

Private ready queues remain distinct from the public task links. The private
`CI386Heap`, stack bounds and exception-chain records are not aliases for public
`CHeapCtrl`, `CTaskStk` or `CExcept`. Their public service integration, task family
lists, documents and window state remain unfinished. Complete record storage does
not imply that every field already has working service semantics.

The private compiled getter probes do not expose public `Fs`/`Gs` in startup source
or prove native JIT loading of the full headers. Class completion across inputs now uses
[private transactions](i386-class-completion.md) in the owning task scope. Actual
public-header loading and service integration remain required before that step.
