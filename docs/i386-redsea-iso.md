# RedSea ISO generation reference

The complete FileMgr still rejects missing RedSeaISO at line 407. Its provider
is `Adam/Opt/Boot/DskISORedSea.HC`, loaded with `BootDVD.HC` by BootDVDIns.
The operation allocates temporary drive/device records, creates a file-backed
RedSea volume, writes ISO descriptors and an El Torito catalog, recursively
copies the source tree and optionally installs/patches a stage1 loader.

`tools/test-i386-redsea-iso.py` exercises the original public function with both
an explicit stage2 payload and FileMgr's default omitted-stage2 call. The source
contains an empty directory, a nested three-byte file, a 4,097-byte file and a
1,537-byte synthetic stage2. Ten independent guest booleans check generation,
alignment, mounted exact file reads, empty-directory existence, read-only image
device type, unmount and the default-call round trip.

The host independently parses both exported images and verifies descriptor
identifiers, little/big-endian volume/block/root values, RedSea geometry,
El Torito checksum and boot entry, directory self/parent records and recursive
file bytes. It requires an empty loader area for the default call and nonzero
loader bytes for the explicit-stage2 call. Both images are 55,296 bytes in the
reference. Directory timestamps and the volume unique ID vary; whole-image
byte equality is not an oracle. The synthetic stage2 is not executed, so this
is not boot qualification or complete loader-relocation verification.

`build/i386-redsea-iso-original-v3/result.json` passes all ten guest checks and
both host parses, with unchanged inputs. Its terminal audit independently
checks the table and every execution input hash. The original v1 guest checks
passed, but the host parser incorrectly treated a subdirectory's named self
record as a child cycle. `RedSeaMakeDirectoryCore.HC` and the emitted records
confirm that this record uses the directory name, not a literal dot. Corrected
v2 passes the explicit-stage2 case; v3 adds the default call. All frozen runner
and fixture versions are retained.

`build/i386-redsea-iso-native-baseline-v1/result.json` rejects RedSeaISO at fixture
line 16 before assertions; execution inputs were unchanged. That baseline used
the earlier eight-check fixture, preserved in its run directory.

Native generation remains missing. Its required implementation includes the
complete original descriptor/copy/device lifecycle and an architecture-appropriate
boot-loader path. Original BootDVD's stage1 explicitly requires x86-64 via CPUID;
copying those bytes unchanged would not qualify 386 native boot. ISO creation,
boot payload/handoff, allocation-failure cleanup and complete FileMgr/C1–C5
qualification remain open.

```
python3 tools/test-i386-redsea-iso.py --out build/redsea-iso-original
python3 tools/test-i386-redsea-iso.py build/IMAGE/kernel.img --out build/redsea-iso-native
```
