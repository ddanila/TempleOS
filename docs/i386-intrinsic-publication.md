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

`Kernel/I386/Intrinsic.HH` supplies 32 canonical public declarations to the
disk-backed `StartOS.HC`: bit tests and updates, port I/O, character conversion,
integer/F64 conversions and the supported mathematical operations, frame access,
and flags access. Their signatures and opcode values match `Kernel/KernelB.HH`
and `Compiler/CompilerA.HH`. The validator additionally supports FS and GS
getters, but public `Fs`/`Gs` declarations await complete `CTask`/`CCPU` migration.
The test's private byte-pointer getters do not establish those public APIs.

`CompilerIntrinsicProbe.HC` exercises a 34-declaration input on both boot and
worker tasks. It checks valid metadata before mutating declarations to exercise
12 rejection cases, then restores and publishes the same input. Fresh compiler
contexts execute 14 cases covering task/CPU/frame identity, flags preservation,
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
