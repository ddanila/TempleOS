# Public formatting command

Console interface 229 shares the complete original `Fmt` body through
`Kernel/BlkDev/FormatCore.HC`. It retains the original public U8 drive argument,
quick/confirm defaults, FAT32 choice on ATA devices, RedSea fallback on other
devices, confirmation, current-drive changes and cache invalidation. The
implementation uses the existing original FAT32Fmt and RedSeaFmt providers.

The fixture uses only an isolated 108 KiB RAM device mapped temporarily as Z,
with its filesystem at block 88. The same fixture runs on pinned original
TempleOS and the normal native image through public interfaces. Sixteen checks
cover cancellation with exact unchanged device bytes, confirmation text,
FAT32-to-RedSea fallback, current drive and silent state, preserving data after
a quick format and outside the partition, directory/file writes and exact
reads, unsupported filesystem rejection without mutation, full-format clearing,
removal of old files and a new file round trip after formatting. Cleanup
restores the previous directory, output document, drive map and silent state.

Original v1 found fixture mistakes: FileWrite returns a filesystem allocation
result rather than the requested byte count, and PrintErr prefixes its message
with caller information and ERROR. Corrected v2 checks successful allocation,
exact subsequent file contents and the stable error-text suffix. It passes all
sixteen checks with unchanged execution inputs. The earlier native baseline
rejects Fmt at fixture line 31 before assertions, also with unchanged inputs.
Both historical fixtures and runner copies are preserved under their run paths.

Evidence is under `build/i386-format-original-v2`,
`build/i386-format-native-baseline-v1` and
`build/i386-format-source-parity.json`. The latter verifies byte-for-byte parity
of the shared function body. The original v2 saved builder helper preserves its
input pin when the on-disk verifier advances from interface 228 to 229; the disk
reader AST is unchanged.

ATA FAT32 formatting, exceptional cleanup and full FileMgr workflows still
require separate qualification. These RAM-drive checks do not close C1–C5.

```
python3 tools/test-i386-format.py --out build/format-original
python3 tools/test-i386-format.py build/IMAGE/kernel.img --out build/format-native
```

Both bootstrap generations pass in `build/rebuild-format-v1-verified`. The
native cross-build exports and source audit pass in `build/i386-format-cross-v1`;
only ConsoleRuntime and the kernel interface version differ from interface 228.
`build/i386-format-native-v1` passes all sixteen checks and concluding arithmetic
pixels at 64 MiB KVM, with unchanged inputs. The terminal audit independently
checks the expected table and original/native byte equality. The full enclosing
diagnostic/interactive cross-build remains running.

Loading the complete original FileMgr now passes Fmt and rejects the missing
RedSeaISO at line 407 (`build/i386-pick-dir-format-v1`, unchanged inputs). The
chooser itself remains unqualified.

The full 16 MiB diagnostic now reaches both program-probe phases and passes
the exact welcome frame (`build/i386-format-cross-v1/diagnostic16-audit.json`).
Enclosing interactive/rejection checks are still running.
