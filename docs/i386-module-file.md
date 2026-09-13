# Native modules loaded from RedSea

`Kernel/I386/ModuleFile.HH` and `ModuleFile.HC` connect the native RedSea reader
to the existing shared module validator/loader. `I386RedSeaLoad` takes a mounted
volume, a file entry, an exclusively owned heap and the requested entry symbol.
It returns a heap-owned executable image/trampoline, or zero on failure. It does
not call the entry point or start a task. The caller owns execution lifetime and
releases the image with `I386HeapFree` only after all calls/references have ended.

The bridge accepts one contiguous uncompressed regular file. It validates the
volume/extent, rejects directory/deleted/resident/compressed entries and impossible
module sizes, allocates a temporary file buffer, and requires a complete read.
The shared `I386LoadAlloc` validates the target/ABI, module records, executable
entry and references before returning a separate image. The temporary file buffer
is freed on every normal success/failure path. Peak allocation includes both the
serialized module and its loaded image; this does not stream relocations from disk.

ATA/RedSea boot ownership still applies: IF clear, a quiescent exclusively owned
channel and live input records. The heap also requires exclusive ownership and
valid metadata. Inputs stored in that heap must be live allocations, not bytes
in a free region that the loader could overwrite. Returned code and data are
independent of the file buffer. Disk errors, heap exhaustion, invalid modules and
missing entries return zero; no exception or OutMem policy is added.

`I386RedSeaLoadSet` accepts a contiguous array of file entries and links all of
them into one image using the same entry-symbol convention. Input count/address
ranges and every file extent are validated first. It allocates temporary pointer/
size tables and file buffers, resolves cross-file function and data imports through
the shared loader, then frees all temporary allocations. A failure at any stage
cleans earlier file buffers too. Count one uses the original single-file path.
The file list is explicit: there is no automatic dependency search, registry or
binding to resident kernel symbols. Peak memory includes all serialized modules,
the temporary tables and the combined image.

`python3 tools/test-i386.py --redsea-load` cross-compiles a module with mutable
64-bit global data and exports its serialized bytes into the fixture's RedSea
volume. A separate direct-execution case audits the same module's executable/data
ranges. Native code locates the file, loads it, calls the entry, overwrites a new
allocation in the reclaimed file-buffer space, and calls the entry again. It
repeats load/free and checks that global data resets and the heap is fully reclaimed.

Negative cases include a wrong pointer-width marker, truncated/tiny files,
compressed attributes, missing entry symbols, no room for the file buffer, room
for the file but not the loaded image, and a real read error after one sector.
The host requires the backing disk to remain unchanged. The 128 KiB runner stage
ends at 0x30000; this fixture's heap is 0x40000–0x50000, below its 0x90000 stack.
This is development evidence on QEMU 486/8 MiB, not physical 386 validation.

`python3 tools/test-i386.py --redsea-load-set` compiles a consumer importing a
function and mutable 64-bit data from a provider. It loads both file orders,
overwrites the exact reclaimed tables/file-buffer allocation, and verifies calls
and data state before fully reclaiming the heap. Cases reject a missing provider,
duplicate providers, wrong-width/truncated dependencies and a missing entry.
Heap exhaustion covers tables, each file and the final image; a real read error
in the second file checks cleanup of the first. The single-file suite is rerun
as a regression. Both payloads are also audited/executed as a direct linked case.

Automatic dependency discovery, resident kernel symbol binding, a module
registry/unloading policy, compressed files, public file/task APIs and integration
into the production boot/JIT path remain pending. This bridge does not establish
native compiler self-hosting or a complete standalone OS.
