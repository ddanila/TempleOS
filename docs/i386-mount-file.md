# File-backed mounting

The complete original mounting dependency bodies are now shared source units:

- `BlockDevAddCore.HC` retains lock forwarding, RAM and image initialization,
  ATA whole-drive and partition traversal, FAT32 initialization, and ATAPI setup.
- `BlockDevDeleteCore.HC` retains drive release, stream closure, owned filename
  and device-record cleanup, and block-device clearing.
- `FATInitCore.HC` retains the full FAT32 boot/info-sector initialization.
- `Adam/ABlkDev/MountFileCore.HC` retains complete `Unmount` and `MountFile`.
- The other ten units retain complete FileRead/FileWrite, FileFind, Cd, DirMk,
  and RedSea/FAT32 read, write, directory-change and directory-creation bodies.

Each implementation body occurs unchanged in the preceding committed original
source; only trailing blank lines were removed. Original call sites include
these units in their previous order. Both generations of the original
compiler/kernel rebuild passed (`build/mount-shared-rebuild-v2.log` and
`build/rebuild-test/result.json`). This extraction does not add native bindings
or change the native file-service interface.

`tools/test-i386-mount-file.py` supplies a paired original/native contract for
subsequent integration. It formats a private RedSea RAM filesystem starting at
sector 88, writes a real image file, calls the complete MountFile, checks drive
geometry and backing-device lock forwarding, reads through absolute and relative
paths, verifies read-only block writes are rejected, and unmounts and cleans up.
The native mode uses real public APIs and contains no mounting stubs.

The rebuilt-original contract passes with unchanged inputs at
`build/i386-mount-file-reference-v6/result.json`. Earlier fixture attempts had
undeclared private helpers, oversized exception tags, and an omitted argument
to the fixed-arity dynamic RedSeaFmt call. Those attempts do not qualify behavior;
the final fixture calls the unmodified routines with their full arguments.

Native mounting remains unqualified. Before publishing MountFile, mapped drives
outside the retained ATA volume provider must use the complete original file and
directory services, including FAT32 branches. Provider dispatch must identify
known backends even after quarantine, so a failed retained volume cannot bypass
its failure state through a fallback. The terminal right-click callback still
needs this closure; DocTermNew and the C1-C5 release audit remain open.
