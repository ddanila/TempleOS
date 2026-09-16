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

The core remains internal behind the retained public allocation interface below.
Debug headers, heap logging, fragment tidying and adjacent-page merging are not
yet implemented. The region and growth providers remain internal; full memory
integration also needs public `BlkPoolInit`/`BlkPoolAdd` metadata accounting,
remaining allocation convenience functions, and migration of compiler allocation
ownership to the task/code heap policy. Low-memory/latency acceptance remains open.

## Native public allocation interface

`PublicMemory.HH`, included by `PublicKernel.HH`, loads the complete shared memory
records and declares twelve resident entry points. The original allocation aliases
are retained for `MAlloc`, `Free`, `MSize`, `MSize2` and `MHeapCtrl`. Module-owned
system export records also bind `CAlloc`, `MAllocAligned` and `CAllocAligned`.
The metadata and executable addresses have kernel lifetime; a native compiler
control owns only its declarations. Header loading uses the existing transactional
class completion and include guards. The original `Memory/BlkPool` help-file
registration stays in `KernelA.HH`; native-loadable shared records retain their
help indexes without requiring native `#help_file` support.

| Interface | Native contract |
| --- | --- |
| `MAlloc` / `CAlloc` | A null selector uses the current task's data heap. An explicit `CTask` selects its data heap; a `CHeapCtrl` selects that control directly. `CAlloc` zeros the requested bytes. Zero-byte requests still produce an owned allocation. |
| `Free` | Null is a no-op. Resolve an aligned marker to its original allocation, free through its owning control, then notify the backing provider after all page-header reads are finished. Cached small-object pages remain owned until heap teardown. |
| `MSize` / `MSize2` | Null returns zero. Report the original allocation's capacity, or its span including the 12-byte native used prefix. For aligned pointers this preserves the original base-capacity behavior; it does not subtract the alignment displacement. |
| `MHeapCtrl` | Return the actual owning control after resolving any aligned marker; null returns null. |
| Aligned allocation | Require power-of-two alignment and nonnegative size/misalignment within checked native bounds. Reserve room for the marker and displacement; `CAllocAligned` zeros the requested payload. |
| `MemCpy` / `MemSet` | For a nonnegative byte count, copy forward or fill with the low byte of the value, returning the pointer just past the written bytes and clearing the direction flag. Zero-length calls do not dereference either pointer. Overlapping forward copies follow the original primitive, not move semantics. |
| `MAllocIdent` | Null returns null. Duplicate the bytes reported by `MSize` from a live base heap allocation into the selected heap. The source must expose that full readable capacity. |
| `StrNew` | Copy a zero-terminated string including its terminator into the selected heap. Null creates an allocated empty string. |

Exhaustion and unsupported allocation sizes throw `OutMem` after restoring the
caller's interrupt state. An uncaught allocation failure is recorded by the
command runner and displayed as `Out of memory`; source-level `try`/`catch` can
handle it directly. Invalid readable heap/allocation records stop with a
corruption diagnostic. This remains a ring-0 API with live-pointer requirements.
The bootstrap allocator's exact-request size query and private headers are not
interchangeable with this capacity-based public API.

Aligned allocations store a negative I64 displacement immediately before the
returned pointer. The implementation widens both addresses to I64 before
subtracting them: native pointer arithmetic otherwise truncates that displacement
to 32 bits and loses its negative high word. The runtime probe checks the marker
and exercises size, owner and free operations on misaligned results.

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
The retained public-memory service arranges these trim points after public free
and task heap teardown. Provider teardown rejects remaining owned pages or
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
The boot kernel now loads `MemoryRuntime` version 4 after file-service setup and
before native compiler diagnostics or worker creation. Its 16-byte candidate
table contains only binding and probe entry points. Module `Main` publishes no
task state and reserves no backing memory; the kernel validates the target,
imports, version and resident entry addresses before invoking the binding call.
The retained module owns the pool and callback code for kernel lifetime. Binding
allocates the root heap control; children inherit distinct public heap controls
through the existing spawn hooks. Code and data heap pointers alias within each
task on this flat target. Version 2 adds the borrowed kernel symbol table to the
binding call; it publishes allocation exports only after service validation and
root heap attachment. The candidate interface remains 16 bytes.

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
bound. Native header probes exercise allocation lifetime across source inputs,
failed compilation, aligned size semantics and allocation exceptions. Compiler
allocation migration and the remaining full memory services are unfinished.

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

The diagnostic worker retains a private 256 KiB compiler arena until its probes
finish. The initial integration did not actually exit and reap that worker;
the current kernel exits and reaps it before console creation, checking that
at least the arena and stack bytes return to the bootstrap heap. The former 128 KiB arena could
retain the complete public headers but exhausted while compiling the exception
probe. Sharing the bootstrap compiler heap instead passed the source cases but
made the diagnostic startup substantially slower. Compiler allocation migration
therefore remains a separate measured change. The console continues to use the
bootstrap heap for compiler metadata and working storage, and its distinct
public heap for generated executable buffers and user allocations. Neither arrangement establishes the final 8 MiB workload budget.


## Generated code ownership

Final native executable buffers now request storage from the current task's
public code heap. Parser tracking records carry the allocator owner and logical
requested length; publication transfers both the buffer and its owner into task
storage. This preserves the distinction between rounded public capacity and
exact compiler output length. Unbound bootstrap compiler contexts continue to
use their original arena.

The retained memory service owns nonthrowing allocation, capacity and release
callbacks. They survive temporary diagnostic modules and compiler controls.
Release checks heap and pool locks before changing storage. An empty code heap
can return cached pages while retaining its live control and task identity; the
backing provider runs only after page-header reads finish. Task symbol teardown
preflights all retained storage before deleting names, so a locked code heap can
defer reap without losing the callable definition.

Compiler metadata, intermediate representations, symbol records and global data
still use bootstrap storage. This slice does not implement every use of the
frontend's code-heap flag or establish the final memory budget. The native boot checks child publication, execution after compiler cleanup,
locked-heap reap deferral, successful retry and exact bootstrap reclamation in
both root and worker phases. See the progress log for full-suite status.


`Kernel/Mem/AllocCopy.HC` holds the shared `MAllocIdent` and `StrNew` bodies.
The x86-64 allocation implementation includes them directly; the retained native
memory service binds their primitive names to its own allocator, byte copy and
string-length implementation. Native public declarations keep ordinary source
calls unchanged. These helpers propagate allocation failure through the existing
`OutMem` path. Adam-heap convenience wrappers and the remaining public pool and
heap services still require integration.
