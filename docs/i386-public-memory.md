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
A private pool extension records registered backing regions and a validation tag;
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

The core deliberately remains internal. The task ownership adapter below binds
real controls in native lifecycle tests. Retained service loading and binding in
the boot environment, default/current and explicit task heap selection, throwing
`MAlloc` and public `Free`/`MSize` are still required before application exposure.
Aligned-allocation markers, debug
headers, heap logging, fragment tidying and adjacent-page merging are not yet
implemented here. The region and growth providers below remain internal; full
integration also needs public `BlkPoolInit`/`BlkPoolAdd` metadata accounting and migration of compiler
allocation ownership to the task/code heap policy. Public service and
low-memory/latency acceptance remain open.

## Regions and demand growth

Pools can start empty and register discontiguous, page-aligned regions through
`I386MemPoolAdd`. Each `CI386PoolRegion` extends the complete shared `CMemRange`
with a pool owner and used-page-byte count. Registration rejects overlapping
arenas and control records before mutation. Allocations remain within one
registered region, including when two regions are physically adjacent. Address
membership is checked before reading a page-block header.

`I386MemPoolRemove` detaches a wholly unused region. It checks the free lists
before mutation, then removes that region's raw fragments and small/large bin
entries. A heap's cached pages still count as owned pages and prevent removal.
The caller may release or overwrite the backing bytes only after successful
detach. Additional region records are borrowed; pool reinitialization rejects
attached external records rather than discarding their ownership links.

`Kernel/I386/MemoryBacking.HC` supplies an optional growth callback over the
bootstrap allocator. It starts without reserving an arena. An exhausted page
request invokes growth once, with a recursion guard and the pool unlocked; a
corrupt free-list entry is rejected without invoking growth. The provider tries
its growth quantum, falling back to the required page span if the quantum cannot
fit. Large-bin rounding happens once before growth and is preserved on retry.

Each owned region uses one bootstrap allocation containing its record, alignment
padding and page arena. `alloced_u8s` reports usable page bytes; the provider's
`retained` count includes the complete bootstrap allocation span, including its
header and absorbed tail bytes. Caller-owned provider/control storage is separate
from that count. This preserves the distinction between public allocation
capacity and the bootstrap allocator's exact requested size.

`I386MemBackingTrim` returns wholly unused owned regions to the bootstrap
allocator; other regions and live allocations remain usable. Trim is explicit
and must run after heap/free operations finish using returned page headers.
Calling it inside `PageFree` would invalidate a header its caller still needs.
The retained public-memory service must arrange these trim points when it binds
the running kernel's tasks. Provider teardown rejects remaining owned pages or
borrowed regions. An empty provider can grow again without reinitialization.

The native heap fixture exercises three region lifetimes and three provider
lifetimes, alongside the existing allocation corpus. It covers holes, adjacent
regions, overlap/overflow rejection, detach from all bin kinds, cached-page
ownership, growth under memory pressure, failed growth without retained-state
changes, fragmentation, and immediate bootstrap reuse of returned regions.
The fixture's loader permits 192 KiB below its existing first heap at `0x40000`;
the OS hardware and RAM targets are unchanged.

## Task ownership

`Kernel/I386/TaskHeaps.HC` allocates one complete public heap control per task.
Both `code_heap` and `data_heap` point to that control on the flat i386 target.
The owning `CI386TaskHeaps` record uses bootstrap storage with recorded allocation
provenance. Its public control owns pages from a borrowed pool. The provider must
retain the root pool, backing arena and callback code until all users detach.

Children retain their parent's heap state through a child count and the existing
task lifetime-reference count. Spawn attaches heap state before file and symbol
inheritance, then publishes the task to the scheduler. Failure unwinds those
resources and the parent reference. The scheduler rejects partially populated
heap pointer/callback sets, using one shared shape validator to limit bootstrap
code growth.

Normal cleanup and compiler-control draining run while public allocations remain
live. Reap destroys file and symbol state before invoking heap destruction; it
then releases the owned task/stack allocation. Heap destruction rejects active
dependencies and locked controls. A failed reap keeps the remaining heap state
and task identity available for retry. Root heap detach is an explicit provider
shutdown operation from the root task; normal root task exit remains prohibited.

The standalone `--task-heaps` fixture runs four cycles with two workers each.
It covers bootstrap-control exhaustion during spawn, a later inheritance failure
after public allocation, partial hooks, parent-reference overflow, allocations
surviving yields and cleanup, and a locked heap that defers final reclamation.
Synthetic compiler/file/symbol callbacks exercise the actual scheduler ordering;
this does not claim that the native compiler already uses public heaps. Every
cycle restores public pool and bootstrap allocation accounting, with a root
allocation preserved until explicit detach. Hardware IRQs are masked in this
fixture while IF preservation is checked; the existing task suite covers delivery.

Private task extensions now include heap state and callbacks. Dependent runtime
versions are CompilerRuntime 40, FileRuntime 18, CompilerProbe 10 and ConsoleRuntime
6. Their interface table sizes and the shared public task/CPU layouts are unchanged.
The boot kernel now loads `MemoryRuntime` version 1 after file-service setup and
before native compiler diagnostics or worker creation. Its 16-byte candidate
table contains only binding and probe entry points. Module `Main` publishes no
task state and reserves no backing memory; the kernel validates the target,
imports, version and resident entry addresses before invoking the binding call.
The retained module owns the pool and callback code for kernel lifetime. Binding
allocates the root heap control; children inherit distinct public heap controls
through the existing spawn hooks. Code and data heap pointers alias within each
task on this flat target.

The private pool has an optional, non-yielding reclamation notification. Task heap
destruction saves the provider pointer, releases pages and the control, drops the
parent pin and clears task hooks before notifying it with interrupts masked. The
retained provider then returns wholly idle regions. It must not trim within
`PageFree`, because the caller still reads the returned block header. A failed
heap teardown does not invoke reclamation. Provider shutdown rejects an installed
notification before changing state; the owner must detach it explicitly.

The task fixture now uses growing backing storage and checks ten reclamation
notifications across failed construction, eight worker teardowns and root detach.
Locked heap destruction preserves both backing totals and the notification count;
successful teardown releases backing while preserving the root allocation. Root
detach returns all backing allocations. Native kernel probes separately allocate
across two regions from the root and a spawned worker and check exact bootstrap
reclamation. Console input checks that its inherited public heap pointers are
bound. The public throwing allocation functions and compiler allocation migration
remain unfinished; this service does not yet expose allocation calls to programs.

## Validation

`tools/check-memory-layout.py` compares all captured x86-64 fields and verifies
the native layout fixture against the target policy. The heap fixture executes
49 native size/offset checks, page-bin reuse and larger-block fallback, small-bin
boundaries, aligned payloads, two heap owners, 1024 allocation/free rounds with
payload and accounting checks, and three heap lifetimes reclaimed with live
allocations. Its 256 KiB arena ends below the boot stack. Code loading allows
192 KiB below the original first arena; the OS memory target is unchanged.

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
python3 tools/test-i386.py --task-heaps
python3 tools/test-i386.py --tasks
python3 tools/build-i386-kernel.py --test
```

Measured outcomes and remaining integration work are in
[port progress](port-progress.md).
