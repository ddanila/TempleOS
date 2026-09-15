# Public memory records and native allocation core

The original allocation, page-pool and heap-control records are shared between
`KernelA.HH` and the native memory core. `MemoryAllocTypes.HH` contains the normal
allocation headers, `MemoryAllocDebugTypes.HH` retains the original debug variant,
and `MemoryTypes.HH` contains page blocks, ranges, pool/control records and their
constants. The native core currently uses the normal headers only.

The x86-64 baseline was captured before extraction. The fixture records all six
classes and 43 fields, including zero-size aliases, pointer depth and array count.
Its i386 policy changes pointer widths while preserving explicit integer widths.
The heap hash remains 1024 bytes on both targets.

| Record | Original x86-64 bytes | Native i386 bytes |
| --- | --- | --- |
| `CMemUnused` | 16 | 12 |
| `CMemUsed` | 16 | 12 |
| `CMemBlk` | 24 | 16 |
| `CMemRange` | 40 | 28 |
| `CBlkPool` | 2528 | 1276 |
| `CHeapCtrl` | 1120 | 1088 |

`Kernel/I386/Memory.HC` implements an internal allocation core over these complete
public records. It does not cast the bootstrap `CI386Heap` into `CHeapCtrl`.
A private pool extension records its caller-supplied arena and validation tag;
the public pool fields hold the actual free lists, page bins and byte counters.
Heap controls hold actual owned-page lists, free fragments, allocation bins,
owner pointers and counters. The caller owns the control records and backing arena.

Page allocation uses 512-byte pages, exact small page bins, and power-of-two-plus-
two large bins. A larger returned block can satisfy a smaller request in its
entirety. Small object allocations use byte-size-indexed bins below 1024 bytes;
new fragments come from owned page blocks. Large objects own separate page
blocks. `used_u8s` counts live object spans including their headers, while
`alloced_u8s` counts owned pages, including retained small-allocation fragments.
Destroying a heap returns all its pages, including pages containing live objects,
and invalidates the control. Reinitialization starts a fresh heap lifetime.

The original normal free and used size fields still overlay one another at
native offset four. A used header starts at four modulo eight, so its 12-byte
prefix ends at an eight-byte-aligned payload. For a large allocation, the page
block starts at offset zero, the used header at offset 20, and the payload at
offset 32. Up to four tail bytes are excluded when rounding the usable span down
to eight bytes. There is no target-specific padding added to public records.

All mutations mask interrupts on the single-CPU profile. Nested pool operations
preserve the outer interrupt state. Allocation, free and teardown reject locked controls instead of spinning.
Constructors require exclusive, inactive control records. No NMI use is supported.
Control records, live allocation pointers and
their exclusively owned arena must be readable/writable as appropriate; this is
not a memory-protection boundary for arbitrary ring-0 pointers.

The core deliberately remains internal. Retained service loading, default/current
and explicit task heap selection, binding `CTask.code_heap`/`data_heap`, throwing
`MAlloc`, public `Free`/`MSize`, control-record allocation and task teardown are
still required before application exposure. Aligned-allocation markers, debug
headers, heap logging, fragment tidying and adjacent-page merging are not yet
implemented here. Full integration also needs growth across backing regions,
public `BlkPoolInit`/`BlkPoolAdd` metadata accounting, and migration of compiler
allocation ownership to the task/code heap policy. Public service and
low-memory/latency acceptance remain open.

## Validation

`tools/check-memory-layout.py` compares all captured x86-64 fields and verifies
the native layout fixture against the target policy. The heap fixture executes
49 native size/offset checks, page-bin reuse and larger-block fallback, small-bin
boundaries, aligned payloads, two heap owners, 1024 allocation/free rounds with
payload and accounting checks, and three heap lifetimes reclaimed with live
allocations. Its 256 KiB arena ends below the boot stack. Code loading allows
128 KiB below the original first arena; the OS memory target is unchanged.

The existing arena-heap tests also exposed a range check that relied on pointer
expression wraparound. `I386HeapRegionValid` now checks the wide address sum
explicitly, rejecting regions that cross or end at 4 GiB before writing either
control or arena. The fixture checks both cases and unchanged state on rejection.

Run the x86-64 bootstrap first, then the layout and native checks:

```sh
python3 tools/test-rebuild.py
python3 tools/check-memory-layout.py
python3 tools/check-task-layout.py
python3 tools/test-i386.py --heap
python3 tools/build-i386-kernel.py --test
```

Measured outcomes and remaining integration work are in
[port progress](port-progress.md).
