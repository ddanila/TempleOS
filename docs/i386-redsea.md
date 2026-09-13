# Native RedSea reads

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

Filesystem writes/allocation, cache and task locking, decompression, public file
APIs, resident module loading from files, complete image consistency checks and
physical 386/IDE validation remain pending.
