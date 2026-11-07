# DVD image I/O

The original `DVDImageRead`, `DVDImageWriteTask` and `DVDImageWrite` bodies are
shared through `Kernel/BlkDev/DVDImageCore.HC`. The existing native ATAPI packet
routines supply the lower layer. Full optical writing requires additional
qualification beyond exposing the original public functions.

`tools/test-i386-dvd-image.py` attaches a disposable 133,120-byte patterned DVD
as the secondary IDE slave. Its fixture maps a temporary optical drive with
known geometry and reads it into a FAT32 RAM filesystem. All bytes are compared
independently on the host, including the final partial copy batch. The writer
is then called with a non-optical target and must throw BlkDev before enabling
write override; the source image is read again and must be unchanged. Eight
guest booleans check sizes, data and device lock/flag state.

The test instruments an in-memory copy of the shared Guest helper only to add
the extra QEMU drive, preserving its original command handling and snapshots.
Every run records its actual QEMU arguments, frozen fixture/runner and input
hashes. The original reference is pinned by the existing reference-restoration
tool; the patterned DVD contents are generated independently from `(i*13+5)&255`.

`build/i386-dvd-image-original-v3/result.json` passes all eight checks and both
133,120-byte comparisons with unchanged inputs. V3 keeps both exported buffers allocated through the
capture interval; v2 passed but could reuse the first freed buffer for the
second read, so v3 is the retained comparison. Original v1 instead used a
RedSea RAM destination and raised Drv in BlkWrite from DVDImageRead: FOpen
forces contiguous files on RedSea, but this function supplies no preallocation.
Its exception screenshot is preserved. The corrected test uses FAT32 streaming;
this does not claim to repair or qualify original RedSea destination behavior.
The native interface-230 baseline rejects missing DVDImageRead before assertions,
with unchanged execution inputs.

The configured drive geometry bypasses discovery. Successful optical burning,
producer/consumer task recovery, device errors, exceptional heap cleanup and
complete FileMgr/C1–C5 remain unqualified. The original writer's rejected-device
path also allocates before throwing; this test makes no heap-recovery claim.

```
python3 tools/test-i386-dvd-image.py --out build/dvd-image-original
python3 tools/test-i386-dvd-image.py build/IMAGE/kernel.img --out build/dvd-image-native
```

Console interface 231 provides both public signatures and the shared MT_CD /
MT_DVD constants. Both full bootstrap generations pass in
build/rebuild-dvd-image-v2-verified; the earlier core-only rebuild is preserved
separately and is not the integration gate. All 1,734 production source hashes
match after exports in build/i386-dvd-image-cross-v1. Runtime comparisons and
the enclosing full cross-build are tracked separately.

`build/i386-dvd-image-native-v1` passes all eight checks, both exact byte streams
and concluding arithmetic pixels at 64 MiB KVM. Its terminal audit verifies
every input pin, the independent expected table/pattern, original/native equality
and complete original function-body parity. Both public services are retained;
the write producer and successful burning path are not qualified by this test.

Complete original FileMgr loading now passes DVDImageWrite and rejects missing
SettingsPush at line 588 (`build/i386-pick-dir-dvd-image-v1`, unchanged inputs).
The chooser workflow and all C1–C5 gates remain open.

The full 16 MiB diagnostic boot in `build/i386-dvd-image-cross-v1` now reaches
both program-probe phases, both code-heap ownership cases, both file-break
cleanup cases and `DONE native kernel startup`. All 307,200 welcome pixels
match the exact oracle (`diagnostic16-audit.json`). The enclosing interactive
regression remains running; this is not a full-suite or startup-timing result.
