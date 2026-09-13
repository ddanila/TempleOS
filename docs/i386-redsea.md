# Native RedSea file access

`Kernel/I386/RedSea.HH` and `RedSea.HC` connect RedSea metadata and raw file reads
to the native ATA driver. All calls inherit ATA's exclusive, quiescent channel
ownership with IF clear. Volume, disk, entry, name and data buffers must remain
live; output storage must not overlap the input records. This is an initial
filesystem interface, not yet the public CDrv/CFile implementation.

The format follows `Doc/RedSea.DD`, `Kernel/KernelA.HH` and
`Kernel/BlkDev/FileSysRedSea.HC`: 512-byte sectors, absolute sector addresses,
64-byte directory records with 38-byte names and 64-bit block/size/date fields.
Parsing reads fixed little-endian fields independently of host pointer layout.
The bitmap follows the boot sector; file extents must begin after the bitmap.

Mount checks both signatures, the recorded drive offset, volume bounds, bitmap
coverage, root extent and the root's first `.` record. The recorded offset must
match the supplied sector; relocated images are not silently rebased. Directory
self records must name their own sector and describe a positive whole-sector
extent. Failed mounts preserve the caller's volume record. Mount does not scan
allocation bits or establish consistency between all extents and the bitmap.

Find accepts one exact, case-sensitive name of 1–37 bytes and a directory sector.
It validates the directory self record, streams subsequent directory sectors,
skips deleted records and stops at the first zero name or declared directory end.
Live records require terminated names, contiguous non-resident storage and an
in-volume extent. It returns 1 on success, 0 when absent and -1 for invalid input,
malformed metadata or disk error. The destination entry changes only on success.
Nested traversal is explicit: find a directory, then search its returned block.
Path parsing, wildcards and public filename policy remain separate work.

Read accepts a file entry, byte offset, caller-owned output buffer and count.
It validates the extent, clips the request at EOF and rejects destination ranges
that cross the 32-bit address-space boundary. It copies from one sector
buffer, so partial sectors and files larger than the scratch buffer do not require
whole-file allocation. RedSea and ATA each use a 512-byte sector buffer on the
stack, in addition to normal frames. Directory/resident/deleted records and negative ranges
are rejected. Compressed files are returned as raw stored bytes; this interface
does not expand `.Z` files. A failure before copying any bytes returns -1;
a later I/O failure returns the number already copied, leaving the remaining
output untouched. EOF or a zero-length valid request returns 0. Invalid requests
do not modify the output. Callers must handle short reads.

`RedSeaWrite.HC` adds `I386RedSeaWrite` for raw updates within an existing file's
fixed extent. The entire requested range must fit the declared size; writes are
not clipped or grown. Read-only, directory, deleted, resident and non-contiguous
entries are rejected. Partial sectors are read before modification, preserving
neighboring file bytes and the final sector's padding. Whole sectors are written
directly. The source buffer remains unchanged. The API returns the number of
confirmed bytes, or -1 if none completed; a failed sector may nevertheless have
changed on the device. There is no rollback. Zero-length valid writes return 0.
Callers explicitly flush via `I386AtaFlush(volume->disk)` when required.

These low-level writes leave size, timestamp, attributes and allocation metadata
unchanged. They operate on raw stored bytes even for compressed files. Creation,
growth, metadata updates, recompression and public FileWrite semantics require
higher-level services and are not implied by this interface.

`RedSeaAlloc.HC` implements contiguous bitmap allocation and release. Bitmap bit
indices use `block - (volume->first - 1)`, matching the existing RedSea data-area
convention: bit zero represents the last bitmap sector. Allocation scans from the
first data sector and uses the first sufficient free run; it returns its absolute
sector, 0 for fragmentation/exhaustion, or -1 for invalid input/I/O failure. It does
not zero data, create an entry or flush. This uses first-fit scanning rather than
the x64 implementation's in-memory best-fit free list.

Release requires an extent owned by the caller and no longer referenced by a
live directory entry. It rejects metadata/out-of-volume ranges, the root directory
extent and any range containing already-free bits. All bits are preflighted before
any bitmap write, so a mixed allocated/free range is rejected without modification.
Both operations update one bitmap sector at a time. A bitmap I/O failure clears
the volume signature, preventing reuse of that view until explicit recovery and
remount. Earlier bitmap sectors may already have changed; remount alone does not
repair partial allocation/release. There is no transaction or automatic rollback.

Allocation assumes the existing bitmap accurately describes live extents; these
helpers are not a filesystem consistency checker or an ownership registry.
One exclusive mounted view must own mutation; callers must not bypass failure
invalidation through a second alias. Publishing/removing directory entries,
ordering data and bitmap flushes, and recovering interrupted updates are work
for the higher-level file operation. Low-level release must not be used on a
still-referenced file or subdirectory.

The native fixture is `python3 tools/test-i386.py --redsea`. The host lays out a
RedSea volume on a 16 MiB IDE disk alongside the runner. It includes a directory
spanning two sectors, a deleted entry with deliberately invalid storage, nested
HolyC source, a 1300-byte binary file, an empty file and a malformed live extent.
Additional boot records exercise malformed signatures, sizes, bitmap and root
bounds, with a corresponding valid volume. Native checks cover lookup, full and
unaligned/EOF reads, full-width timestamps, unchanged failure outputs, and explicit directory rejection.
An overstated disk/volume profile reaches a real device error after one successful
sector, checking both partial and zero-progress error returns. The host requires
the entire backing image to remain unchanged.

`python3 tools/test-i386.py --redsea-write` checks partial/full/partial sector
updates, overlapping overwrites, an EOF update and explicit flushes. It verifies
source preservation, readback, zero-length requests, rejected attributes/ranges
and partial/zero-progress failures against a real out-of-range device write.
The host compares the complete disk image against precisely the intended byte
updates, including the first confirmed sector of the fault test. File padding,
directory metadata, the bitmap and other sectors must remain unchanged.

`python3 tools/test-i386.py --redsea-alloc` uses an 8192-sector volume with two
bitmap sectors. It verifies exact bits after an allocation crossing that boundary,
fragmentation, mixed-range/double-free rejection, full exhaustion and reclamation.
Root/bitmap reservations and unused tail bits remain intact. A forged device bound
forces a real bitmap read error and checks view invalidation. The host requires
complete image equality after all successful allocations are released. Partial
bitmap-write and power-loss failures are not yet fault-injected.

Directory mutation and allocation policy integration, cache and task locking,
decompression, public file APIs, resident module loading from files, complete image consistency checks and
physical 386/IDE validation remain pending.
