# Fixed-width directory filename conversion

`CFileNameTo`, used by the original RedSea and FAT directory lookup paths, is
shared through `Kernel/BlkDev/CFileNameToCore.HC` and exposed by ConsoleRuntime
196. It clears the entire 38-byte destination before validating the source,
then copies a valid name. Expanding the include in the original source
reproduces its preceding bytes exactly.

The original-body fixture checks ordinary names, invalid separators, dot and
parent names, empty and null input, 37- and 38-byte boundaries, zero filling
and canaries on both sides. The original pre-extraction and shared bodies pass
mask 127 with unchanged inputs (`build/i386-cfilename-to-original-v1` and
`build/i386-cfilename-to-original-v2`). The preceding native image rejects the
missing binding before executing any case (`build/i386-cfilename-to-native-red`).
Both original rebuild generations pass (`build/i386-cfilename-to-rebuild-v2.log`);
their binary differences mean reproducibility is not established. Filesystem
lookup, other character classes and allocation/error behavior outside this
nonallocating helper remain unqualified.
The corrected cross-build and 386 instruction audit pass
(`build/i386-cfilename-to-cross-v2`); the 64 MiB native fixture passes all
seven checks with unchanged inputs and a byte-identical delivered fixture
(`build/i386-cfilename-to-native-v1`). The concurrent run does not qualify
startup timing. An earlier cross-build rejected an incompletely initialized
expanded export bitmap; the corrected build initializes the new word explicitly.
