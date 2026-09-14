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
all possible references into a task arena. Automatic control-list cleanup and
public task/code-heap policy still require integration.

## Retained services and tests

CompilerRuntime version 13 changes the constructor's calling convention to carry
the optional owner; its record remains 56 bytes and its imports remain twenty.
FileRuntime version 4 adds compiler configuration and a three-argument current-task
constructor, making its record 32 bytes with six function pointers. Its eighteen
imports are unchanged. The kernel validates all addresses, configures the factory
once, and retains both providers for the kernel lifetime.

The standalone disk probe now creates its control through FileRuntime using a
relative filename. Boot and worker phases verify the resolved name, scope,
lifetime reference, nested plain/compressed includes, archive-error recovery,
IF-set reading and exact reclamation after destruction.

The task-symbol fixture checks default-name preservation, C:/ and D:/Child relative
names, bitmap selection, root-only/one-time configuration, ABI rejection, IF
preservation, reference saturation and allocation failure. An owned input survives
a failed construction and is reused successfully. Document-callback rejection
keeps the task reference until a valid retry. A control survives its task's finish
and is deleted from the root before final reaping. The fixture uses a 256 KiB test
transfer ending at its 0x50000 arena; the standalone reservation is unchanged.

Verification commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --task-symbols
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

These checks pass on the QEMU/486 development profile. The factory implements the
context-selection part of construction; it is not yet the complete public
`CmpCtrlNew`/`CmpCtrlDel` contract. Public task records and heap/error policy,
control-list teardown, actual prompt/document input, parser/JIT and self-hosting
remain required.
