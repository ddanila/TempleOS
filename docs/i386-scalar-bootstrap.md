# Native scalar-type bootstrap

CompilerRuntime ABI 30 (180 bytes) adds `bootstrap_scalars`, `load_scalar_types`
and `scalar_types_check`. The retained module now supplies an owned frontend
context for the shared expression, type, declaration and class/header parsers.
It imports `SysTry` and `SysUntry` in addition to its previous 21 kernel providers.
FileRuntime remains ABI 13/32 bytes; CompilerProbe remains ABI 5/56 bytes.

## Production boot path

After loading the compiler and file services, the kernel calls `load_scalar_types`
to read the original `C:/Kernel/Types.HH` from RedSea. It creates and enters an
AOT compiler control, builds a private symbol table above the current task's table,
and parses the six scalar unions with the shared grammar. Array bounds compile
and execute through the native backend; each temporary output and IR view is
reclaimed before parsing continues.

The bootstrap validates the required declaration order, intrinsic forwarding,
widths, member names, overlapping offsets, array dimensions and 32-bit pointer
variants. These are the original `U16`, `I16`, `U32`, `I32`, `U64` and `I64`
union definitions, including their byte/word/dword member views. Their source links
use the original filename and declaration line; their help index is
`Data Types/Simple`.

Only a complete, valid file is published. The existing class-publication operation
transfers owned class/member/name/metadata allocations into the task's table
without changing their addresses. Unwinding the compiler control frees the private
table, input, lexer state and remaining parser temporaries. Permanent boot classes
belong to the root task's symbol table and are visible through worker inheritance.
The load service records their addresses in the kernel-supplied array and the kernel rechecks the complete scalar schema and
address identity after the temporary CompilerProbe image has been released.

The fixed conventional-memory boot reservation remains 384 KiB. Parsing and schema
validation live in the retained compiler module in extended memory; the kernel
only invokes the services and reports lifetime checks.

## Ownership and failures

`bootstrap_scalars` requires an active, owned AOT control with its task's global
table selected, no compiler errors and no outstanding code allocations. It uses
parser-owned storage and throws on parse/allocation errors; its caller must unwind
the control. Validation or publication refusal leaves class storage private.

`load_scalar_types` owns file buffers and the controls it creates. Its optional
`roots` output supplies storage for six class pointers, recorded only on success. It unwinds to
the caller's previous control boundary on every path. Expected compiler and
out-of-memory exceptions return false; unexpected exceptions are rethrown after
cleanup. A second load cannot overwrite classes already in the destination table.
An inherited class can be shadowed by a new child-owned class. Completing a
published parent extern class or replacing a parent function is rejected before
the shared symbol core could mutate that graph.

`scalar_types_check` borrows the current task's live table and a six-pointer array. Recording writes
that array only after all six symbols validate; later checks require the same
addresses. It neither allocates nor extends their lifetime.

## Verification and limits

The standalone suite runs seven bootstrap cases in each of the boot and worker
tasks: successful load and duplicate rejection, malformed array bound, premature
EOF, wrong intrinsic signedness, missing input, exhausted heap and invalid help index. Each restores
exact heap byte/allocation counts, compiler controls, task references, exception
state and interrupt state. Successful temporary loads check all twelve source
links against declaration lines in the packaged original file, then detach and
free the class graphs. A separate `SCALAR LIVE` check compares permanent root classes after probe
release with the addresses recorded by the boot load service.

This environment is sufficient for scalar bootstrap. ABI 31 adds retained
expression output and function defaults; see
[i386-frontend-expressions.md](i386-frontend-expressions.md). General statement/global
integration, static initialization, register/define matching, AOT data storage and
named function/global linking remain unfinished and explicitly reject unsupported
operations. Source links and
help indices do not yet provide DolDoc navigation or the complete metadata system.
There is no interactive HolyC shell or native self-hosted rebuild yet. The QEMU/486
8 MiB development profile does not establish strict 386SX/DX compatibility.

Run `python3 tools/test-rebuild.py` followed by
`python3 tools/build-i386-kernel.py --test`. The shared lexer backup helper also
has coverage through `python3 tools/test-i386.py --lex-state`.
