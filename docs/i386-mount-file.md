# File-backed mounting and mapped media

The native console now retains the complete original MountFile, Unmount,
BlkDevAdd, BlkDevDel and FAT32Init bodies. Mounting includes the original RAM,
file-backed image, ATA partition, extended-partition and ATAPI branches. Those
hardware branches are retained, not all qualified by the file-image contract.

Public FileRead, FileWrite, FileFind, Cd and DirMk dispatch mapped drives outside
the retained ATA provider to complete original implementations. Both RedSea and
FAT32 branches are present. Mounted-drive listings and the full listing option
use the complete original Dir and file/directory link writers. The original
FAT32 formatter is retained as well; its x86 boot-sector opcode constants keep
their original values. Dir's native declaration now includes the original full
argument. Existing retained-provider short listings keep their previous path.

The identity-only backend query uses the current task's volume table and matches
physical device, filesystem and geometry. It deliberately does not call
I386RedSeaValid: quarantining an existing backend must not select a fallback
that bypasses that backend's error state. The diagnostic checks canonical and
copied records, null, changed geometry/filesystem, quarantine, and a substituted
per-task volume table. All nine checks pass mask 511 in the final v6 staged build.
File services are version 65 (34 pointers, 144 target bytes); the console is
version 204 with 573 public/internal bindings. The loader/verifier checks all
file-service addresses, including the previously unchecked trailing services.

The original source sharing began in commit 1134724d with fourteen complete
units. Three further units share FAT32Fmt, Dir, PutFileLink and PutDirLink.
Implementation bodies are unchanged apart from trailing blank lines; source
wrappers include them in the original order. The DVD loader-size constant is
shared with the native block-size definitions.

The paired MountFile contract formats a private RAM filesystem starting at
sector 88, writes an actual contiguous image file, mounts it, checks geometry
and backing-device lock forwarding, reads through absolute and relative paths,
rejects read-only block writes, and unmounts. It passes on the rebuilt original
(`build/i386-mount-file-reference-v7/result.json`) and the final staged native image
(`build/i386-mount-file-native-v4/result.json`), with unchanged input pins.
The native post-mutation outer filesystem has matching reachable extents and
bitmap. No throwing mounting or filesystem stubs are supplied.

The FAT contract passes on rebuilt original and native systems
(`build/i386-fat-path-reference-v4/result.json` and
`build/i386-fat-path-native-v4/result.json`). It uses the full formatter and
initializer on a private 4096-sector RAM device and exercises directories, long
names, compression, Copy/Move, CFile writes, parent/relative reads, enumeration,
and full listing. Original FAT listings include dot entries: eight entries in
this fixture. An independent host reader verifies matching FAT mirrors, three
directories, five files, twenty live clusters, exact plain bytes and compressed
stream metadata. See `tools/test-i386-fat-path.py` for the bounded contract.

The unchanged terminal right-click callback and DocTermNew constructor now both
compile against real services (`build/i386-mount-terminal-constructor-probe-v1`,
inputs unchanged). This is compile-only evidence: DocTermNew remains unpublished
and constructor execution and menu actions remain unqualified. The autocomplete
activation boundary is still the missing global DocTermNew service.

Both mutated native images pass the independent extent/bitmap audit and match
all 1,252 packaged candidate source/documentation files. Two generations of the
original rebuild pass (`build/mount-staged-probes-rebuild-v5.log`).

The staged 16 MiB compiler diagnostic completes both providers in both phases;
the compiler/task/allocator checks pass. Initial registry creation changes its
disk, so the full driver's read-only gate does not pass. The 8 MiB diagnostic
still exhausts memory in root-user-header loading. See
`docs/i386-staged-compiler-probes.md` for exact scope and remaining gates.

ATA partition/optical hardware, arbitrary media failures, broad FAT32 volume and
Unicode behavior, repeated-mount heap recovery, full terminal/autocomplete and
settings integration, workstation release qualification, and C1-C5 remain open.
The original BlkDevInit ownership of FileFind output also needs a repeated-mount
heap audit; record clearing alone is not an exact heap-recovery claim.
