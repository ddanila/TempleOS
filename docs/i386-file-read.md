# Volume paths and owned file reads

`Kernel/I386/RedSea.HC` supplies `I386RedSeaResolve`: a component-by-component
walker over one mounted volume. Absolute slash paths start at the volume root;
relative paths start at the caller's directory block. Repeated separators, dot,
parent entries and directory trailing separators are supported. Parent traversal
reads the target directory's self entry to recover its actual size. Files cannot
be traversed as directories. Components retain RedSea's 37-byte name limit.

The result is 1 for success, 0 for an absent entry and -1 for invalid input or
I/O failure. The output record changes only on success. This is volume lookup:
drive prefixes, backslashes, extension defaults and wildcard expansion are not
accepted pathname features. Callers exclusively own the volume/channel with
interrupts disabled, as with the underlying ATA reader.

`Kernel/I386/FileRead.HC` supplies `I386RedSeaReadAll` for a resolved entry and
`I386RedSeaFileRead` for a path. Successful reads return an owned heap allocation
containing every raw file byte and an additional NUL. Embedded NULs are preserved;
the optional size excludes the added terminator. Empty files return an allocation
of one byte. The caller frees successful results with `I386HeapFree`.

Both readers reject enabled interrupts. Allocation failure, invalid metadata and
incomplete reads return null, reclaim any temporary allocation and leave the
optional size unchanged. Metadata, heap and size output must remain valid and
exclusively owned throughout the call. Raw compressed files are not decompressed.
These functions are lower-level services, not the public TempleOS FileRead API.

KernelStorage uses the path reader for `/Kernel/I386/Kernel.HC`, retaining its
source hash, native lexer traversal and complete heap-reclamation checks. Native
include dispatch still needs public path/extension rules, decompression, file
input ownership and metadata, and integration with compiler controls.

The native `tools/test-i386.py --redsea` fixture checks absolute and relative
paths, repeated/dot/parent components, directory sizes, missing and invalid paths,
unchanged failure outputs, binary and empty file contents, optional size output,
161 exhausted heap arenas, immediate and partial I/O failures, and rejection with
interrupts enabled. The whole disk must remain unchanged. It uses a 128 KiB runner
and a separate 64 KiB heap; this is component evidence on QEMU/486, not strict 386
hardware qualification or a complete interactive-memory measurement.

## Extended-image recovery observer (2026-11-07)

The heap observer now validates the extended boot metadata and derives the
kernel payload base from it, rather than assuming the historical `0x11000`
address. Export bounds, runtime heap signature, arena bounds, exact used bytes
and allocation-count comparisons remain enforced. The resident-include layout
guard now matches the staged file-state record; its typed guest view checks
`busy` at offset 28 and `drive` at offset 32. Both file-read runners accept
`--welcome` for the current desktop startup.

`build/i386-file-observer-extended-v1/result.json` passes on the frozen private-read
candidate at 8 MiB TCG `486,-fpu`: all VGA checkpoints match, inputs remain
unchanged, and the observed heap retains exactly 5,419,624 used bytes and 17,197
allocations across the warmed arithmetic command. The observer's address is
1,058,136, derived from the 1,048,576-byte payload base and the bounded kernel
export. Current-image layout preflight and Python syntax checks pass.

This validates the observer, not the complete file-recovery workflow. The longer
public-read and resident-include recovery runs remain pending. The earlier
`i386-private-read-staging-public-v1` run was explicitly stopped because its
preloaded observer still assumed the obsolete address; its original oracle and
partial guest evidence are preserved. Runtime private-read allocation changes
are separate, unfinished work and are not qualified by this observer check.
