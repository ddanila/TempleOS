# Native i386 arena heap

`Kernel/I386/Heap.HC` is the initial native allocator for bringing up platform
units. It uses the HolyC compiler's i386 backend and has no host, task, interrupt,
or exception dependencies. It does not replace the working x86-64 allocator.

## Contract

- `I386HeapInit(hc, base, size)` creates one heap in caller-owned writable memory.
  The base must be nonzero and eight-byte aligned. Size is rounded down to eight
  bytes and must leave at least 24 bytes. The arena cannot overlap its control
  record or wrap the native address space. Initialization failure changes neither
  the control record nor the arena. Reinitializing a live heap discards all its
  allocations; callers must explicitly own that lifecycle.
- `I386HeapAlloc(hc, size, zero)` returns an eight-byte-aligned payload or NULL.
  Negative, unrepresentable, and unavailable requests fail. A zero-byte request
  gets a distinct allocation with at least eight bytes of capacity. When `zero`
  is true, the requested bytes are cleared. Alignment padding is unspecified.
- `I386HeapSize(hc, ptr)` returns the original requested size, or -1 for an invalid
  heap or a pointer that does not name a live allocation in that heap.
- `I386HeapFree(hc, ptr)` releases an exact live payload pointer and merges
  adjacent free blocks in both directions. NULL succeeds as a no-op. Invalid,
  interior, foreign, and already-freed pointers fail without writes. As with
  ordinary allocators, an old pointer cannot be distinguished from a new live
  allocation that has reused exactly the same address.
- `I386HeapValid(hc)` checks the full block chain and accounting. Allocation,
  non-NULL freeing, and size lookup validate before traversing it for their own
  operation. Invalid metadata causes failure before mutation. Control records and
  the declared arena must still be readable: this is not a memory-safety boundary.

Each block has a 16-byte fixed-width header and at least eight payload bytes.
A first-fit scan splits a free block only when the remainder can hold a complete
block. `used` counts live block spans including headers and absorbed padding;
`peak` is its high-water mark, and `allocations` counts live payloads. Validation
checks aligned spans, bounds, tags, reserved fields, requested sizes, coalescing,
and accounting. Whole-chain validation makes operations linear in block count;
this is an initial correctness-oriented implementation, not a measured final
allocator performance choice.

The caller must serialize access and must exclude firmware, device holes, boot
structures, loaded images, stacks, and other heaps when providing an arena. An
arena is contiguous; separate usable ranges require separate heaps or a later
page-pool layer. Allocation/free do not yield or change interrupt state.

## Integration still required

Extended-memory discovery/reservation, page pools, task heap ownership, interrupt
serialization, task teardown, and public `MAlloc`/`CAlloc`/`Free` wrappers remain
pending. The public TempleOS interface must preserve its `OutMem` exception
semantics; NULL-returning try-allocation here is a lower-level bootstrap API.
`I386LoadAlloc` now uses this heap for native module images; see
[the module API](i386-modules.md#allocating-native-loader).
VGA and module loading now select conventional-memory arenas using the
[BIOS handoff](i386-boot-memory.md). Fixed arenas remain in the isolated heap
stress fixture. Neither establishes the full OS's memory budget.

## Verification

Run `python3 tools/test-rebuild.py`, then `python3 tools/test-i386.py --heap`.
The native test covers guarded arenas, rejected initialization, requested-size
queries, coalescing, exhaustion, zero fill, invalid frees, metadata corruption,
and 512 allocation/free operations with payload checks. `--vga` exercises a
153,600-byte allocation through the real presentation routine and verifies the
entire displayed image after releasing the buffer. Both tests pass on the QEMU
486/8 MiB runner; they do not prove physical 386 support or full-OS RAM usage.
