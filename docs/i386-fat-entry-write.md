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

The pinned original and the rebuilt original were also tested with separate,
disposable 128 MiB ATA disks containing FAT32 partitions
(`build/i386-fat-disk-original-v5` and `build/i386-fat-disk-shared-v5`). The
pinned system created and reopened short and 24-character files; the rebuilt
system additionally created and reopened 30- and 37-character files. Guest
readback and independent host `mcopy` readback matched their contents. Both
systems reopened the files after a cold reboot without changing the disk hash.
The rebuilt test also fills the root directory: a host-side FAT walk confirms
two padding slots at the end of the first cluster and the 37-character name's
three long-name slots and short entry in the next cluster. `fsck.fat -n` exits
zero; it reports the free-cluster summary as uninitialized. This qualifies the
tested rebuilt-original FAT path, not native FAT mounting or all on-disk cases.

The entry writer now rejects an invalid filename before modifying its output,
sets the returned entry count to zero, and `FAT32DirNew` stops before locking
or writing the disk when construction fails. The shared-original contract
checks an invalid slash-containing name and all output-buffer canaries
(`build/i386-fat-entry-invalid-shared-v2`); the pinned original still passes
the valid-name reference cases (`build/i386-fat-entry-invalid-reference-v1`).
The original compiler and kernel rebuild through two generations
(`build/i386-fat-invalid-rebuild.log`), with binary differences. This does not
establish handling of all malformed names or short-name collisions.
The corresponding native cross-build and 386 instruction audit pass
(`build/i386-fat-invalid-cross`), as does the native contract at 64 MiB with
unchanged inputs (`build/i386-fat-invalid-native-v1`). An attempted direct call
to the internal `FAT32DirNew` from the original disk fixture stopped in the
guest compiler (`build/i386-fat-invalid-disk-v1`); it did not test disk mutation.
The rebuilt-original valid-name disk creation and cold-reopen regression passes
(`build/i386-fat-invalid-disk-v2`). A follow-up uses the public `DirNew` API,
which dispatches to `FAT32DirNew` for the mounted FAT disk: it rejects the
slash-containing name both before and after cold reboot, while the reopen disk
hash remains unchanged (`build/i386-fat-invalid-disk-v3`). The updated fixture
also passes the pinned-original valid-name cases
(`build/i386-fat-invalid-disk-reference-v1`). This covers one invalid name,
not every malformed input or concurrent disk operation.

Previously, two long names with the same generated short alias produced a
duplicate directory entry reported by `fsck.fat -n`
(`build/i386-fat-alias-collision-red-v2`). Directory creation now scans the
locked directory, preserves an existing entry's alias on replacement, and
chooses an unused numbered alias when needed. It updates long-name checksums
and creates a long-name slot when a short name needs a different alias. The
original compiler and kernel rebuild through two generations
(`build/i386-fat-alias-rebuild.log`), with binary differences.

The opt-in `--shared --collisions` disk test now passes with three colliding
long names, replacement of the first two, guest and host readback, cold reopen,
an unchanged reopen disk hash, and a zero exit from `fsck.fat -n`
(`build/i386-fat-alias-collision-v2`). The ordinary disk regression also passes
(`build/i386-fat-alias-normal-v1`). This does not cover all FAT namespace
ambiguities in all creation paths, pre-existing duplicate aliases, malformed
directories, or native FAT
mounting. Directory scanning adds work proportional to directory size and may
scan repeatedly for numbered candidates.

The earlier `--shared --collisions --alias-shadow` test exposed another
ambiguity (`build/i386-fat-alias-shadow-red-v2`): writing a name equal to an
existing short alias created a second entry, and host lookup returned different
contents from guest lookup. FAT file lookup now recognizes short aliases
case-insensitively, and `FAT32FileWrite` resolves an existing alias to its
long name before replacement. The updated test reads through the lowercase
alias, writes through the uppercase alias, and checks the original long name
and alias in the guest and on the host. It passes cold reopen, unchanged reopen
hash and `fsck.fat -n` (`build/i386-fat-alias-lookup-v2`); the collision control
also passes (`build/i386-fat-alias-lookup-control-v2`). The boundary-padding
assertion is skipped in the alias test because replacement can reuse those
deleted slots. This covers `FileRead`, `FileFind` and `FileWrite` for the
tested alias; direct `DirNew`, pre-existing ambiguities and concurrent
operations still need separate coverage.

FAT deletion now also accepts an exact short alias case-insensitively. For
streamed `"w"` opens, the existing FAT entry is resolved to its long name
before deletion and replacement. The rebuilt-original test combines deleting
one file through its lowercase alias with a one-block streamed replacement of
another through its alias; guest and host readback, cold reopen and
`fsck.fat -n` pass (`build/i386-fat-alias-stream-delete-v1`). The preceding
whole-file alias-write case remains passing
(`build/i386-fat-alias-stream-control-v2`). The final tests also pass after
making the exact-alias deletion honor file-type filters
(`build/i386-fat-alias-stream-delete-v2`). The original compiler and kernel
rebuild through two generations with binary differences
(`build/i386-fat-alias-delete-filter-rebuild.log`). These checks do not cover all
stream modes, wildcard deletion, cross-cluster long-name deletion or races.

`FAT32DirNew` currently returns false even on successful writes, so the earlier
invalid-name API test's return value alone does not establish rejection. Its
unchanged cold-reopen disk hash and the entry-writer canary test provide the
relevant evidence for that case.
