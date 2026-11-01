# FAT short-name helpers

`FATNameTo`, `FATNameXSum` and `FATFromName` are shared in
`Kernel/BlkDev/FATNameCore.HC`. They are dependencies of FAT directory entry
lookup and construction; they do not implement FAT traversal.

The pinned original `FATNameTo` can write beyond its 11-byte output for names
outside 8.3. The reference executes that exact pinned body with a larger buffer:
`a.long` writes a twelfth byte, and a 37-character name writes beyond the short
name field (`build/i386-fat-name-bound-original-v3`, mask 1535). The preceding
native image shows the same result on its saved screen, failing the bounded
expectation (`build/i386-fat-name-bound-native-red-v2`); the runner times out
and its inputs remain unchanged.

The shared implementation now caps output at 11 bytes while still consuming
all input. This intentionally differs from the original's writes outside that
field, preserving the first 11 bytes and avoiding the overwrite. The corrected
shared body passes the same fixture on the original runtime with mask 3839
(`build/i386-fat-name-bound-shared-original-v2`). The fixture also covers
ordinary 8.3 conversion, uppercasing, dot entries, invalid names, padding and
checksums. Separate in-memory long-name construction checks are described in
[FAT entry construction](i386-fat-entry-write.md); FAT traversal remains open.
Both original rebuild generations pass (`build/i386-fat-name-bound-rebuild.log`);
their binary differences do not establish reproducibility.
The native cross-build and 386 audit pass (`build/i386-fat-name-bound-cross`).
The native 64 MiB run passes mask 3839 with unchanged inputs and a
byte-identical delivered fixture (`build/i386-fat-name-bound-native-v1`); its
concurrent startup does not qualify the timing gate.
