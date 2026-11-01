# FAT short-name helpers

The original `FATNameTo`, `FATNameXSum` and `FATFromName` bodies are shared in
`Kernel/BlkDev/FATNameCore.HC` and exposed by ConsoleRuntime 197. Expanding the
include reproduces the preceding original FAT source byte for byte. These
helpers are dependencies of FAT directory entry lookup and construction; they
do not implement a FAT filesystem or its cluster traversal.

The pinned original executes the pre-extraction and shared bodies under private
fixture names. Both pass mask 255 for 8.3 conversion, uppercasing, dot entries,
invalid names, padding, checksums and a destination canary, with unchanged
inputs (`build/i386-fat-name-original-v1` and `build/i386-fat-name-original-v2`).
An expanded original fixture also confirms that `a.long` writes a twelfth
byte when given a larger buffer (mask 511, `build/i386-fat-name-original-v3`).
The preceding native image rejects the missing first binding before any case
runs (`build/i386-fat-name-native-red`). Long names, all character classes,
FAT directory entries and storage errors are not covered by this contract.

The original `FATNameTo` does not cap the bytes written after the eight-byte
base; inputs outside 8.3 can write past an 11-byte destination. This shared
body preserves that behavior. Callers need sufficient storage, and the original
FAT entry construction path needs separate long-name and buffer-boundary
qualification before it can be considered safe.

Both original rebuild generations pass (`build/i386-fat-name-rebuild.log`),
as do the native cross-build and 386 instruction audit
(`build/i386-fat-name-cross`). The 64 MiB native fixture passes the expanded
nine-check contract, including the safely observed twelfth-byte write, with
unchanged inputs and byte-identical delivered fixture
(`build/i386-fat-name-native-v1`). These runs do not establish reproducibility,
FAT traversal or the startup timing gate.
