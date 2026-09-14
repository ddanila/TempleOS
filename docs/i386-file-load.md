# Decoded volume-scoped file reads

`I386RedSeaFileLoad` connects native path lookup, raw disk reads and checked archive
expansion. The caller supplies a mounted volume, heap, directory block and path.
The returned allocation contains all raw or expanded file bytes plus NUL; optional
size excludes the terminator and attributes describe the resolved file. Callers
release successful results with I386HeapFree.

Lookup tries the exact path first. Only an absent entry triggers the shared
ToggleZorNotZ rule, applied to the supplied path. Lookup, I/O, allocation and archive
errors stop the operation; an existing broken file is not replaced silently by an
alternate. This makes failure reporting stricter than treating every null read as
a missing name. All temporary names, raw archives and failed output allocations
are reclaimed, and both optional outputs remain unchanged on failure.

FileAttr is now shared with x64 together with the RedSea attribute constants.
Compression is derived from the resolved leaf name, as in original RedSeaFileRead.
A .HC.Z file expands even without the stored compressed bit; a plain .HC name
clears that bit even when stored. The result retains the compressed attribute for
a successfully expanded file. The legacy two-dot and uppercase suffix rules apply.
Dots in the supplied directory path affect alternate-name construction but do not
change compression classification of the resolved leaf.

This is a lower-level volume service. It requires a quiescent ATA channel/volume
and disabled interrupts, rejecting enabled IF before I/O. The existing contiguous,
nonresident RedSea profile still applies. Task drive/current-directory resolution,
parent-directory search, resident caching, default extensions, public exceptions
and compiler include dispatch remain outside this API. The raw FileRead helpers
retain their original contracts.

## Verification

The dedicated `tools/test-i386.py --redsea-read` fixture packages source and binary
archives produced by the original x64 compressor into a native RedSea disk. It
checks exact and alternate names, both directions of .Z fallback, exact-name
precedence, relative directory blocks, binary bytes, empty archives and leaf-name
attribute derivation. Directory-dot/single-extension cases retain legacy rules.

A malformed archive has a valid plain alternate; expansion must fail rather than
use it. A separate directory tests a partial physical disk read under overstated
volume/device bounds, also with a valid alternate. Eighteen small arenas exercise
name/raw/expanded/control/stack allocation failures. Null inputs, unavailable path
syntax, directories, omitted outputs and enabled IF are covered. Successful reads
retain one allocation; failures preserve outputs and heap baselines. The entire
16 MiB disk must remain unchanged.

The fixture fits its 128 KiB loader reservation and uses a separate 128 KiB heap.
Both x64 rebuild generations, existing filename/attribute/raw-read regressions,
native instruction audits and the full kernel boot suite pass. The new decoder
bridge stays outside the 383496-byte bootstrap, preserving its 9720-byte headroom.
File-service module and public compiler integration remain required.
