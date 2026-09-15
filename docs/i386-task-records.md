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

`CompilerTaskLayoutProbe.HC` reparses the full shared definitions for the i386
cross-compiler with explicit opaque dependencies. It asserts all 103 unambiguous
task member offsets against the captured layout contract, plus record sizes and
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

The live native scheduler still uses `CI386Task` and `CI386Cpu`. This extraction
and fixture do not expose a working public `Fs`/`Gs` interface or prove native JIT
loading of the full headers. Next, migrate live state to the shared records,
respecting the public one-byte `catch_except` and wide `except_rbp`, distinguish
public task lists from the private ready queue, and connect the heap/file/task
semantics. Public getters must only be installed once their pointee layouts match
the actual segment records. Cross-input class-completion transactions remain
required for the complete public-header/document environment.
