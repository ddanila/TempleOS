# Original cluster-to-block mapping

The complete original `Clus2Blk` body is shared byte-for-byte through
`Kernel/BlkDev/ClusToBlockCore.HC`. The native candidate appends it to the
ConsoleRuntime 138 public exports, using the existing complete `DrvChk` service.
It handles RedSea identity mapping, FAT32 data-area and sectors-per-cluster
mapping, and the original invalid-drive and unsupported-filesystem exceptions.
It does not implement cluster traversal, allocation, block I/O, or opening files.

The pinned-original contract passes mask 15 with unchanged inputs in
`build/i386-clus-to-block-reference`. It covers both filesystem branches and both
error paths. Both original rebuild generations, cross-build and 386 audit pass,
with 1541 source and 24 build-input hashes unchanged in
`build/i386-clus-to-block-cross`. The 64 MiB native contract passes mask 15 and
all three commands with unchanged inputs in `build/i386-clus-to-block-native`.
Its 64.675399-second startup observation was concurrent and is not a timing gate.
The 8 MiB functional check also passes mask 15 and all three commands with
unchanged inputs in `build/i386-clus-to-block-native-8m`; its 61.356126-second
startup observation was concurrent. Isolated resource gates remain pending.

```sh
python3 tools/test-i386-clus-to-block.py --out ORIGINAL
python3 tools/test-i386-clus-to-block.py IMAGE --out NATIVE
```
