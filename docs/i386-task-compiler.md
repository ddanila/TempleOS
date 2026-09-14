# Compiler controls constructed from a native task

`I386TaskCmpCtrlNew` connects the native control allocator to the current task's
symbol scope and file context. Its configuration borrows the retained compiler
service table, default temporary filename, and the two original character
bitmaps. Initialization validates the service version/size and required callbacks,
is restricted to the scheduler root, and rejects reconfiguration. These borrowed
objects must remain live and stable while the factory is used.

For an explicit filename, the factory borrows the task's directory/drive state,
uses the shared `FileNameAbs` behavior in the scope's heap, and releases the path
borrow before publishing a control. The temporary absolute name is reclaimed
after the control copies it. With no filename, it copies the configured temporary
name unchanged, matching the public constructor's `StrNew(blkdev.tmp_filename)`
branch. The boot configuration uses the original `~/Tmp.DD.Z` value. In particular,
the default name does not become an absolute path just because a task has a
current directory.

The factory selects `char_bmp_alpha_numeric_no_at` for `CCF_KEEP_AT_SIGN` and the
normal bitmap otherwise, exactly as the public constructor does. It supplies the
current task's own hash table, its allocation heap, and the task as the control's
lifetime owner. Input ownership transfers only on successful construction, and
caller IF is preserved.

## Lifetime binding

The low-level constructor accepts an optional native task owner. A bound control
requires a live matching scope in the supplied heap and reserves one task lifetime
reference only after all allocations succeed. The descriptor is appended to the
private allocation wrapper; public `CCmpCtrl` fields/layout are unchanged.

Destruction validates the binding and holds the reference through file/document
callbacks and the complete release sequence. A missing required document callback
rejects without dropping the reference. A finished task cannot be reaped while a
bound control survives, even after its last child scope is destroyed. Another
task may release that control under the existing exclusive-ownership contract;
the original task and its arena remain live until the reference is released.

Unbound low-level controls retain the explicit borrowed-table lifetime contract.
The new pin does not manage separate caller-retained buffers, generated code, or
all possible references into a task arena. Public task/code-heap policy still
requires integration.

## Active controls and task completion

Construction leaves the public control links pointing to itself. Enter registers a
bound control at the tail of its current owner's active queue, optionally retaining
a document-release callback and context. These callbacks/context must remain valid
through cleanup, including after task finish if cleanup needs recovery. Leave can
remove any active control and restores self-links without dropping its lifetime
pin. Deletion also unlinks active controls after validating release requirements.
An explicit delete uses its supplied document callback; automatic drain uses the
callbacks registered at entry.

The scheduler calls the compiler cleanup hook after the user cleanup callback and
before marking the task finished. Drain validates the whole active queue and all
required document callbacks before any release, then deletes controls from the
tail. A missing callback leaves every active control and reference intact. The
scheduler records cleanup failure but still finishes the task, allowing another
task to supply the missing callback through explicit deletion and drain the rest.
Reaping rejects nonempty queues, cleanup failure, busy cleanup or lifetime pins.
Releasing the last active control clears the queue hook and failure flag.

Queue operations preserve caller IF. Document callbacks may yield and must return
normally; they must not throw or finish their executing task. A per-owner busy
flag rejects reentrant control construction, deletion, leave and drain while
release is underway. Owner references remain held through callbacks. Active
operations require the current owner, with leave/delete/drain also allowed for a
finished owner under exclusive ownership. Unbound controls cannot enter a task
queue. This contract does not promise recovery from arbitrary graph corruption.

The task-symbol fixture runs normal cleanup, non-tail detach and missing-callback
recovery with IF initially clear and set. It checks user cleanup precedes compiler
cleanup, LIFO document callbacks, callback yields and rejected reentrant mutation,
rejected early reap, retained detached controls and exact final heap accounting.
Explicit unwind to a preserved enclosing control now runs from a native compiler
catch in the standalone probe; see [i386-compiler-unwind.md](i386-compiler-unwind.md).
Complete parser/generated-code cleanup remains separate work.

## Retained services and tests

CompilerRuntime version 18 retains enter, leave, drain, bounded unwind and
temporary IR allocation/discard alongside construction/destruction and symbol
initialization. Its record is 108 bytes; the
twenty imports are unchanged. FileRuntime version 9 validates that compiler
contract; its own record stays 32 bytes with six function pointers and eighteen
imports. Both providers remain resident for the kernel lifetime.

The standalone disk probe now creates its control through FileRuntime using a
relative filename. Boot and worker phases verify the resolved name, scope,
lifetime reference, active queue entry/exit, nested plain/compressed includes, archive-error recovery,
IF-set reading and exact reclamation after destruction.

The task-symbol fixture checks default-name preservation, C:/ and D:/Child relative
names, bitmap selection, root-only/one-time configuration, ABI rejection, IF
preservation, reference saturation and allocation failure. An owned input survives
a failed construction and is reused successfully. Document-callback rejection
keeps the task reference until a valid retry. A control survives its task's finish
and is deleted from the root before final reaping. The fixture uses a 320 KiB test
transfer ending at its 0x60000 arena; the standalone reservation is unchanged.

Verification commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --task-symbols
python3 tools/test-i386.py --lex-state
python3 tools/test-i386.py --tasks
python3 tools/test-i386.py --except-tasks
python3 tools/build-i386-kernel.py --test
```

These checks pass on the QEMU/486 development profile. The factory implements the
context-selection part of construction; it is not yet the complete public
`CmpCtrlNew`/`CmpCtrlDel` contract. Public task records and heap/error policy,
public compiler-list integration, actual prompt/document input, parser/JIT and self-hosting
remain required.

Native controls now own their current and saved temporary code contexts; their
release shares the public parser's auxiliary-payload policy. See
[i386-code-context.md](i386-code-context.md). Full AOT/generated-code publication
and parser diagnostics remain separate integration requirements.

Native saved and detached code headers now share the parser copy/restore/append
operations; their aliased IR allocations have separate control ownership. See
[i386-code-views.md](i386-code-views.md).
