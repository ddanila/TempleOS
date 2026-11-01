# FAT directory-entry decoding

The original `Dos2CDate` and `FAT32CDirFill` bodies are shared through
`Kernel/BlkDev/FATDateFromDosCore.HC` and `FATDirReadCore.HC`. Expanding the
includes reproduces the previous FAT source byte for byte. The decoder uses
an existing long name when present, otherwise converts the short name, then
copies cluster, size, attributes and timestamp even when the short name is
invalid.

The pinned original and shared original-runtime fixtures pass six checks with
unchanged inputs (`build/i386-fat-entry-read-original-v2` and
`build/i386-fat-entry-read-shared-v1`). The fixture checks short and retained
long names, an invalid short name, directory attributes, a 32-bit cluster and
size, leap-day DOS time and a nonzero local-time offset. The preceding native
image rejects the missing binding before any case runs
(`build/i386-fat-entry-read-native-red`). Both original rebuild generations
pass (`build/i386-fat-entry-read-rebuild.log`), with binary differences; this
is not a reproducibility pass. FAT traversal, full timestamp coverage,
malformed entries and on-disk behavior remain unqualified.
The native cross-build and 386 instruction audit pass
(`build/i386-fat-entry-read-cross`). The 64 MiB native fixture passes the same
six checks with unchanged inputs and a byte-identical delivered fixture
(`build/i386-fat-entry-read-native-v1`). This concurrent run does not qualify
startup timing.
