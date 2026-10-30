# Original FIFO services

MemoryRuntime 30 publishes all fourteen original U8 and I64 FIFO operations,
appended at export indices 50–63. The original CFifoU8 and CFifoI64 records live
in shared Kernel/FifoTypes.HH, and Kernel/KDataTypes.HC includes the shared
Kernel/FifoCore.HC. Every FIFO function body is byte-identical to the original.
Native allocation/free use the existing task-owner-aware memory provider; no
separate ring implementation or substitute flush routine is introduced.

The pinned-original control passes mask 127 in `build/i386-c4-fifo-reference`,
with unchanged execution inputs. It covers all fourteen operations, empty-output
preservation, full rejection, wrapping, ordered peek/removal, flush/reuse,
one-slot capacity, high I64 bits, enabled/disabled caller interrupts, default
and explicit current-task ownership, selected-child ownership and heap used-byte
recovery, plus 128-value producer/consumer transfers for both widths. These are
valid power-of-two FIFO sizes; allocation-failure and multiprocessor stress
qualification remain outside this contract.

These services are needed by original God input routines and the full DocPutKey
path. FifoI64Flush also appears in the original window manager. This does not
qualify those callers or replace their remaining dependencies. Both bootstrap generations pass in `build/rebuild-test`. The cross-build and
386 audit pass in `build/i386-c4-fifo-cross`; `input-audit.json` records all
1535 source and 24 build pins unchanged. MemoryRuntime grows from 237080 to
245224 loaded bytes. The previous native image rejects the absent FIFO API as
expected in `build/i386-c4-fifo-native-red`.

The expanded final fixture transfers 256 values for each width, including every
U8 value. It passes mask 127 on the pinned original in
`build/i386-c4-fifo-reference-byte-range`, and all three native commands at
8 and 64 MiB in `build/i386-c4-fifo-native-8m-byte-range` and
`build/i386-c4-fifo-native-64m-byte-range`. Every run reports unchanged inputs.
The earlier 128-value native runs also pass; their executed fixtures and runners
are preserved in their evidence directories. Interrupt-state coverage applies
to ring operations; construction/deletion use the original caller flags.

The final native runs pause the window manager and were not isolated. Their
63.221146-second (8 MiB) and 62.968430-second (64 MiB) startup observations do
not qualify the startup budget. An isolated FIFO-candidate startup gate and
16 MiB diagnostics remain pending. The public and forward declarations now preserve the original b/_b and q/_q
parameter names. Both original rebuild generations and the combined cross-build
and 386 audit pass with that correction. The 8 MiB FIFO contract passes all
three commands with unchanged inputs in `build/i386-c5-deduplicate-fifo-names-8m`.
Its 61.725797-second startup observation was concurrent and is not an isolated
resource qualification.
All C1–C5 milestones and all 686 inventory entries remain unqualified.

```sh
python3 tools/test-i386-fifo.py --out ORIGINAL
python3 tools/test-i386-fifo.py IMAGE --out NATIVE
python3 tools/test-i386-fifo.py IMAGE --ram-mib 8 --out NATIVE_8M
```
