# FAT directory entry construction

`FAT32DirFill` now constructs up to three long-name slots followed by the short
entry, covering the original 37-character directory-name limit. It emits slots
in descending ordinal order, marks the last slot, writes termination/padding,
and uses the bounded short-name converter. `FAT32DirNew` now reserves four
entries for that result; the prior three-entry buffer and two-slot writer could
not safely represent the longest names. The date encoder, FAT entry type and
writer are shared with the native runtime.

The pinned original writer and decoder pass three reference cases: an 8.3 name,
a 13-character name and a 25-character name
(`build/i386-fat-entry-write-original-v4`). The corrected shared writer and
decoder pass those plus 26- and 37-character names
(`build/i386-fat-entry-write-shared-v3`). The fixture checks returned entry
count, slot ordinals, checksum, decoded name, selected termination and padding
bytes, file size and canaries. The original reference does not run the unsafe
longer cases. Both runs preserve their inputs.

The previous native image rejects the missing `FAT32DirFill` binding before any
case executes (`build/i386-fat-entry-write-native-red`). The original two
bootstrap generations pass (`build/i386-fat-entry-write-rebuild.log`), with
binary differences; this is not a reproducibility pass. These in-memory tests
do not exercise on-disk FAT mutation, cluster boundaries, collision handling,
full Unicode, invalid names, exception cleanup or all timestamp fields.
The native cross-build and 386 instruction audit pass
(`build/i386-fat-entry-write-cross`), and the 64 MiB native fixture passes all
five cases with unchanged inputs and a byte-identical delivered fixture
(`build/i386-fat-entry-write-native-v1`). This concurrent run does not qualify
startup timing.
