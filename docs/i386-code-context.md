# Native intermediate-code ownership

The shared parser represents pending compilation as a `CCodeCtrl`: an
intermediate-code queue and a queue of auxiliary `CCodeMisc` records. The latter
own label names, string data, jump-table arrays, floating-point constant arrays,
array-dimension lists and selected detached symbol graphs. References between
instructions, labels and classes remain borrowed within that graph.

`Compiler/CodeCtrl.HC` now supplies common queue initialization, instruction and
auxiliary-record initialization, and release. The public `ICAdd`, `COCInit`,
`COCMiscNew` and `COCDel` use these helpers. Instruction initialization retains
opcode/precedence, 64-bit data and line numbers, class pointers, pass-trace and
lock flags. Auxiliary address initialization must use the original `I64_MAX`
invalid-pointer marker, converted to the pointer width of the compiling host.

Release walks the full ownership graph, using the existing shared symbol-release
policy for hash records. It leaves empty queue heads after release. Public label
warnings and the final undefined-label diagnostic remain in the public wrapper;
its exception occurs after owned resources are released. When multiple undefined
labels exist, every retained name is now freed, while the last name supplies the
existing final diagnostic. The old loop lost earlier retained names.

Native controls initialize an empty code context at construction. `I386ICAdd`
and `I386COCMiscNew` allocate in that control's heap and publish nodes only after
allocation succeeds. They preserve IF and require the current live task owner,
or an exclusively owned unbound control. They return null on allocation failure;
this remains a bootstrap boundary pending public allocation/OutMem integration.

`I386COCDiscard` silently releases the current graph for recovery, preserving saved
enclosing contexts. Native control destruction releases the current graph and
then restores and releases each saved code context before releasing input and the
control itself. Saved records follow the original `COCPush` convention: copied
queue endpoints still refer to the fixed active header, and each context must be
restored there before traversal. These saved records and every owned graph payload
must belong to the control heap and have exclusive, acyclic ownership.

Silent discard does not implement successful-compilation label validation or
public compiler diagnostics. It also does not own published machine code, every
AOT structure, or borrowed task symbols. Full native parser/JIT integration must
continue to apply their distinct release and publication rules.

The retained compiler exposes instruction allocation, auxiliary-record allocation
and discard alongside its existing control services. The standalone exception
probe attaches temporary IR to a child before raising `Compiler`; catch-boundary
unwind must reclaim that IR and the child input together. Retry creates and
discards a fresh instruction before releasing the replacement child.

The task-symbol fixture covers all eight auxiliary kinds, borrowed references,
64-bit fields, trace/lock flags, multiple undefined names, allocation exhaustion,
saved contexts, discard/reuse and final task-bound control cleanup, with IF clear
and set. The existing lexer-state fixture exercises empty-IR unbound controls.
The x86-64 rebuild and native function corpus check the shared public path.


Verification passes both x86-64 rebuild/reboot generations, all 233 native function
cases, `--task-symbols`, `--lex-state`, and the complete standalone 8 MiB QEMU/486
suite, including executable-region instruction audits. The task-symbol fixture
now uses a 320 KiB transfer ending at its 0x60000 heap arena. The lexical-state
fixture uses 256 KiB ending at 0x50000, with independent scratch arenas at 0x61000
and 0x62000. These test changes do not raise the standalone boot reservation.

CompilerRuntime version 16 uses an 84-byte record, still with twenty imports.
FileRuntime version 7 validates that dependency without changing its 32-byte
record or eighteen imports. The kernel has 43 export bindings. CompilerRuntime
uses 204888 image / 204904 heap bytes; FileRuntime uses 123968 / 123984. The probe
uses 85608 / 85624 and is reclaimed after its task call. The kernel is 389312 bytes;
with its 2160-byte loaded stage, 391472 of the fixed 393216 bytes are occupied.
These are local-change builds with source hashes recorded in the manifests.
Strict 386 profiles, native parser/JIT and self-hosting remain required work.
