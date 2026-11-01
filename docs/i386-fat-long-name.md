# FAT long-name decoding

`DirLongNameFill` decodes the low bytes of FAT long-name entries into the
original 38-byte `CDirEntry.name` field. Its entry type and decoder are shared
through `Kernel/BlkDev/FATLongEntryTypes.HH` and `FATLongNameCore.HC`. The
native runtime checks that the FAT entry remains 32 bytes.

The pinned original decodes the first 25 characters but drops the 26th and
ignores a third entry. The reference executes the pinned body under a private
name and observes mask 255 for one/two slots, checksum and metadata rejection,
state reset and that truncation (`build/i386-fat-long-name-original-v3`). The
shared decoder intentionally differs for longer names: it copies all thirteen
characters from the second slot and up to eleven from a third, retaining space
for the terminator. It passes the corrected original-runtime reference with
26- and 37-character names (mask 895,
`build/i386-fat-long-name-shared-original-v1`). The native prior image rejects
the missing binding before any case runs (`build/i386-fat-long-name-native-red`).
All three reference runs preserve their inputs.

This is only the decoder. FAT directory traversal, UTF-16 semantics beyond the
original low-byte behavior, ordering and checksum coverage beyond the fixture,
malformed slot sequences, and construction of names longer than 25 characters
remain unqualified. In particular, the original writer and its three-entry
buffer are not yet extended for a third long-name slot.

Both original rebuild generations pass (`build/i386-fat-long-name-rebuild.log`),
as do the native cross-build and 386 instruction audit
(`build/i386-fat-long-name-cross`). The native 64 MiB fixture passes mask 895
with unchanged inputs and byte-identical delivered fixture
(`build/i386-fat-long-name-native-v1`). These concurrent runs do not establish
reproducibility or the startup timing gate.
