# Native declarations of resident symbols

The native frontend uses the existing `CHashExport` system records visible through
the task's hash-table chain. An `extern` declaration whose name identifies a system
export receives its resident address through the shared global-declaration parser.
Explicit `_extern` aliases use the same address binding. The declaration supplies
its HolyC type and calling convention; system export records contain addresses,
not complete function signatures.

`FrontendResident.HC` records the private declaration, export identity and borrowed
address. Function resolution accepts a registered native output or a visible
system export. Data aliases use the existing `GVF_ALIAS` ownership rule. Before
publication, every resident binding must still refer to the same visible export
and address. Function addresses must be nonzero and fit the 32-bit address space;
data exports may identify address zero. Changing a declaration's address,
changing/removing its export, or introducing a conflicting destination definition
rejects publication without transferring ownership.

A declaration may coexist with its underlying export in the destination table.
Other definitions with the same name remain collisions. Publication transfers the
normal owned symbol metadata, including arguments and defaults, but never transfers
or frees the resident code/data or the export record. A declaration-only input can
publish without allocating retained executable storage. The compiler's private
binding records are discarded with its control; later inputs use the published
ordinary HolyC declaration.

The export and its code/data must remain live while any published declaration,
generated caller or child scope can use them. The production boot kernel's exports
have kernel lifetime. Temporary providers must retire all dependent declarations
and callers before removing their exports or freeing code. Automatic module pins,
unload dependencies and definition replacement remain open architectural work.

## Startup and verification

`Kernel/I386/StartOS.HC` declares `StrCmp`, `SysTry`, `SysUntry` and `throw` from the
resident kernel. Keyboard submissions can call them after the startup compiler
control is destroyed. Generated `try/catch` uses the original shared statement
grammar and native exception runtime. The complete public `CTask`/`Fs` view and
original runtime headers still require integration.

`CompilerResidentProbe.HC` runs seven cases in both boot and worker phases. It
publishes borrowed function and data declarations, destroys their original
control, and calls them from fresh controls. A data export borrows the current
task's catch flag so generated code can handle a real exception. Cases change
function/data addresses, change or remove an export and add a conflicting
symbol; rejected publication preserves heap/storage counts and succeeds after
restoring the binding. The declaration-only case retains no executable storage.
Fixture teardown restores heap, control, task-reference and interrupt state and
removes its temporary exports before the probe module is unloaded.

Run the x64 rebuild and complete standalone verification:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
```

These checks run on the QEMU/486 development profile. They do not establish strict
386SX/DX compatibility, complete public APIs, DolDoc or native self-hosting.

The full native diagnostic boot has a 90-second observation allowance in the
standalone and keyboard harnesses. The expanded probe corpus reached the previous
60-second cutoff while still advancing through its cases; per-command and screen
response deadlines remain unchanged. Measured startup time is retained in the
result manifest and remains distinct from vintage-hardware latency acceptance.
