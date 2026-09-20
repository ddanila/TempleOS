# Native public hash-table ownership

These validated services supply task-owned tables needed by original document
dictionary initialization; they do not complete DocInit.

MemoryRuntime 8 publishes HashTableNew, HashTableDel, HashDel and HashLstAdd using
public task heaps. Native StartOS loads PublicHash.HH, which also declares the
existing retained HashAdd/HashFind calls with their public signatures. The private
compiler arena table API remains separate and must not be passed to these public
destructors.

Kernel/HashTablePublicCore.HC shares the original creation, traversal and list
ordinal policy through explicit allocator/destructor callbacks. Bucket allocation
uses sizeof(CHash *) instead of a fixed eight-byte shift. The public constructor
still expects a power-of-two bucket count. Parent tables are borrowed and are not
deleted with a child. HashLstAdd copies names and preserves @ aliases and duplicate
lookup ordering.

Cleanup handlers are installed before acquiring an unpublished table or list
entry. A failed bucket allocation releases its table record. A failed name copy
releases its unpublished entry while earlier inserted entries remain owned by the
table. The original exception propagates; these handlers do not mark it caught.
HashDel uses the existing shared standard-symbol ownership visitor, preserving
its separate executable-code lifetime policy.

Standard system-symbol destruction depends on HTT type bits. DolDoc's private
DHT values overlap those bits but describe generic dictionary entries; those
custom dictionaries need a matching generic-entry destructor. Do not apply
HashTableDel/HashDel blindly to a DHT dictionary. This distinction remains part
of the forthcoming native document initializer and failure cleanup.

Hash flag definitions now have a shared header, and CHashGeneric is declared with
the base hash records. Field order and values are unchanged. MemoryRuntime adds
SysTry, SysUntry and HashFind imports; its two-entry service record size is unchanged.

A shared corpus checks collisions, aliases, ordinal values, parent lookup,
duplicate instances, empty lists, task heap ownership and parent survival after
child destruction. Native root/worker diagnostics additionally force bucket and
name-copy failures, preserve IF and require final heap reclamation. Interactive
checks call the retained public bindings from native HolyC.

## Validation

Both x64 rebuild/reboot generations and the full native QEMU/486, 8 MiB suite
passed. The original and native public-table corpus returns 10; native root and
worker phases additionally verify bucket/name-copy allocation failure cleanup.
The interactive run passes 168 commands across 231 lines, seven hardware break
cases, eleven document-lock commands and eight document-selection cases, with
exact VGA output. Startup recovery and all 17 module rejection cases pass.

The manifest matches all 1117 OS source hashes and nine build-input hashes.
The kernel is 363304 bytes, leaving 25816 bytes after the 4096-byte early stage
in its 393216-byte reservation. MemoryRuntime 8 retains 142520 bytes. Measured
normal boot is 16.105 seconds and diagnostic startup is 129.578 seconds on this
run. These are QEMU/486 results, not strict 386 or physical-machine acceptance.
