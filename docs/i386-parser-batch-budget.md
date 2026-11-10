# Parser allocation packing versus heap fragmentation

Changing the default home from C:/ to C:/Home exposes a diagnostic failure after
phase-one expression tests. The original production receipt is
`build/default-home-production-regressions-v1/result.json`; User8MiB and public
home paths pass, but diagnostics fail before the program vectors in phase one.

A disposable CompilerProbe with stop-line markers locates line30 of
CompilerParserMemoryProbe.HC (`default-home-parser-diagnostic-v1`). A second
trace records each allocation pair without changing the assertion:
phase-one pair1 consumes96 bytes, with a64-byte payload block. Its requested
payload is still37 bytes. The batch consumes5640 bytes and128 allocations;
the assertion assumes at most5632 bytes. Both instrumented runs preserve inputs.

This is the allocator's existing unsplittable-tail rule. A37-byte request needs
56 bytes including its header; when the selected free block is64 bytes, the
remaining8 bytes cannot form the minimum24-byte free block and are absorbed.
The16-byte tracking record still occupies32 bytes. Heap.HC/HeapAllocateBlock.HC
already implement this rule, and the stock heap corpus explicitly tests absorbed
tails. The live-heap packing assertion mistakenly assumes no such fragmentation.

The tested candidate keeps the64 live-task allocations, exact37-byte sizes,
boundary bytes,128 allocation count, reverse release and exact used/count/heap
recovery checks. It measures the unchanged88-byte packing limit separately in
a fresh16KiB arena using an unbound compiler control. That arena also explicitly
checks the37-byte request absorbing an8-byte tail while retaining exact requested
size and full recovery. All temporary arena/control resources are released.
No allocator policy, public API or numerical packing limit is changed.

`default-home-parser-budget-prototype-v2` compiles successfully. Its disposable
diagnostic image passes both PARSER BATCH BUDGET and PARSER MEMORY PROBE phases,
both program-probe phases, and document diagnostic load/growth recovery/unload
(`default-home-parser-diagnostic-v3`). The complete386 instruction audit and
independent exact marker-count audit pass under
`default-home-parser-budget-instruction-v1`. The source delta is preserved as
`docs/patches/i386-parser-batch-budget-prototype.patch`.

Prototype v1 has an unavailable NULL callback argument and is excluded as invalid
source setup; its compiler screenshot and exclusion receipt are retained. V2
uses literal0. The tested correction is applied locally for a fresh production
classic/cross rebuild and full focused regression queue. Production qualification
is pending; prototype results alone do not establish that gate or C1-C5.
