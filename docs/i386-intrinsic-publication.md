# Native intrinsic declarations

`Compiler/I386/Intrinsic.HC` validates the native backend's currently supported
intrinsic declaration signatures. An `_intern` function stores an intermediate
code opcode in `exe_addr`; this value is not an executable address or a resident
export. Publication transfers owned symbol metadata into the task scope without
retaining an executable allocation for the declaration.

Validation checks the opcode, argument count, return and argument types, pointer
depth, and incompatible function/import/relocation metadata. `RT_PTR` and
`RT_I64` have the same raw-type value in TempleOS, so pointer depth is checked
independently. Numeric aliases follow their class forwarding records. Current
task/CPU/frame getters accept pointer return types; this does not validate the
layout or semantics of a user-declared pointee class.

The frontend also validates intrinsic call descriptors before binding them for
native code generation. Existing backend checks still apply. This is not a new
instruction implementation or a complete intrinsic catalog: unsupported opcodes
cannot be published through this path.

`Kernel/I386/Intrinsic.HH` supplies 34 canonical public declarations to the
disk-backed `StartOS.HC`: bit tests and updates, port I/O, character conversion,
integer/F64 conversions and the supported mathematical operations, frame access,
string length, and flags access. Their signatures and opcode values match `Kernel/KernelB.HH`
and `Compiler/CompilerA.HH`. The validator additionally supports FS and GS
getters. Public `Fs`/`Gs` now use the shared complete task/CPU records through
native public-header loading; the test also retains private byte-pointer getters.

`CompilerIntrinsicProbe.HC` exercises a 35-declaration input on both boot and
worker tasks. It checks valid metadata before mutating declarations to exercise
15 rejection cases, then restores and publishes the same input. Fresh compiler
contexts execute 18 cases covering task/CPU/frame identity, flags preservation,
wide Boolean and integer operations, software F64 and bit operations above bit
31. Port-I/O declarations are validated here without issuing device transactions.
After removing the published symbols, heap usage, allocation counts, task
references, compiler controls, retained storage and interrupt state must return
to their starting values before unloading the probe module.

The standalone verifier requires both phase completion markers and all rejection
markers. Keyboard tests separately use the public startup declarations and check
their VGA-rendered results. They also check that the console executes with
interrupts enabled and preserves that state after syntax and exception recovery.
Fresh scheduler entries deliberately start with IF clear; the console now enables
it before compiling startup source, once its devices and task services are ready.
Previously input could arrive while the idle task waited, concealing the disabled
interrupt state during console execution.

Run the x86-64 rebuild before the standalone suite:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
```

This integration does not complete public task/CPU records, remaining language
and runtime providers, DolDoc, native self-hosting or strict 386 hardware
acceptance. The full scope remains in [PLAN.md](../PLAN.md).

Native `GetRSP` now reports ESP through the original pointer-returning signature.
Public-stack probes verify its range in boot and worker tasks and through the
interactive console. See [stack ownership](i386-public-stacks.md).

## Public string length

`StrLen(U8 *st)` now lowers opcode 0x84 to a native byte scan, returns a
zero-extended I64 length, and evaluates its pointer argument once. The scan reads
through the terminating byte without wider loads or allocation and neither uses
nor changes DF, matching the original template's direction-independent behavior.
As in the original API, the caller must supply a readable zero-terminated string.
The generated function retains the normal i386 register/stack convention.

The 244-case backend suite includes six cases also executed by the original x64
compiler: empty strings, interior pointers, bytes above 127, embedded terminators,
single evaluation, a 1024-byte string, nested calls and wide result arithmetic.
The cross-target fixture explicitly declares the intrinsic in its compilation
scope. Its instruction audit now accepts the 386 `INC` instruction used by the
scan. Native boot/worker probes add four execution cases and reject scalar or
pointer-to-pointer arguments and pointer return types without changing published
state. Normal-boot keyboard tests exercise the actual startup declaration.

The full native suite passes with 116 commands/179 input lines and exact VGA
checks. Normal startup measures 22.178 seconds; diagnostics measure 177.808
seconds on QEMU/486 with 8 MiB. Both x64 rebuild generations pass. The kernel
remains 388928 bytes, with 192 bytes free after the early stage in its reservation;
CompilerRuntime is 1299168 image bytes / 1299184 retained heap bytes. This closes
one DolDoc dependency. Public string copy and queues were subsequently added;
document lifecycle integration remains open.


## Public queue intrinsics

`Kernel/I386/Queue.HH` publishes the original U0 signatures for opcodes 0x80–0x83:
`QueInit`, `QueIns`, `QueInsRev` and `QueRem`. Validation requires a single pointer
to the complete eight-byte CQue with self-typed next/last members at offsets 0/4.
Lowering uses four-byte loads/stores, evaluates arguments once and allocates no
memory. Removal updates neighbors and leaves the entry's own links unchanged.

The same nine-stage corpus runs under original x64 intrinsics, cross-generated
i386 code and native boot/worker compilation. It checks empty/singleton/multiple
entries, both insertion directions, removal, 32 churn rounds, side effects and
wide markers adjacent to links. The backend suite now has 245 cases and retains
its instruction audit. Native probes reject five malformed signatures per phase
with unchanged symbols and heap accounting.

Public startup now provides 38 declarations across Intrinsic.HH and Queue.HH;
the existing isolated 35-declaration intrinsic probe remains separate. The queue
header retains its help index, but native #help_file parsing and publication are
still missing. See the DolDoc dependency inventory for that integration gate.
