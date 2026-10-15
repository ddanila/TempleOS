# Public string utility contracts

Directory contexts need `MStrUtil`, `StrOcc`, `StrFirstRem` and `StrLastRem`.
Their full original implementations already compile in Console through
ScannerRuntime.HC, but Console 113 does not expose these public bindings.
The shared fixture calls the public functions directly; it does not implement
a path parser or replace the original utility bodies.

Eleven contracts pass on the pinned original system in
`build/i386-c4-string-util-reference`, with masks of 7 and unchanged inputs:

| Case | Observation |
| --- | --- |
| Character count | NULL, repeated and missing characters |
| First segment | Marker is a character set; first delimiter removed |
| First segment without delimiter | Entire string copied and source emptied |
| Last segment | Tail copied and source shortened at last delimiter |
| Last segment without delimiter | Entire string copied and source emptied |
| Omitted output buffer | Return NULL while still mutating source |
| Occurrence pointers | Exact first/last pointers and missing-marker NULL |
| In-place normalization | Same returned pointer; leading/trailing whitespace and embedded control removal |
| Allocated normalization | Leading/trailing trim, single spaces and uppercase |
| Tab expansion | `a\tb` becomes `a       b` |
| Indent scaling | Original F64 factor 0.25 turns one leading tab into two spaces |

Each case also requires unchanged caller document roles and exact caller data
heap recovery. Allocated results are freed before measuring. These are bounded
contracts, not allocation-failure, cancellation, cross-owner or every-flag
qualification.

The native red gate in `build/i386-c4-string-util-prerequisite-red` rejects
`StrOcc` while compiling the fixture, before any behavior cases run. This is API
unavailability, not a native behavior result. Reproduce with fresh output paths:

```sh
python3 tools/test-i386-string-util-reference.py --out OUT-original
python3 tools/test-i386-string-util.py IMAGE --out OUT-native
```

The Console-114 candidate exposes seven existing complete implementations:
StrOcc, StrFirstOcc, StrLastOcc, StrFirstRem, StrLastRem, StrUtil and MStrUtil.
Public flags come from canonical StringUtilFlags.HH; signatures and defaults
match the original API. No utility body is shortened. It adds permanent export
entries and increases Console's public export table from 276 to 283.
Bootstrap, cross-build, native behavior, normal 8 MiB startup and the unchanged
provider footprint cap require qualification before claiming a native pass.

The older Console-113 debug replay is independent: its compiler reads source
files embedded in its writable source.img copy. Before candidate edits, four
key embedded source files were compared byte-for-byte with host files, and
the original image and Compiler/Console export files were hashed in
`build/i386-native-console-debug-snapshot.json`. Preserve those replay inputs;
new builds use a separate output directory. This lifts the earlier blanket
host-source freeze without altering the replay's compiled source epoch.

## First native candidate and memory regression

The Console-114 image in `build/i386-c4-string-util-cross` builds after a passing
bootstrap. The kernel remains 570800 bytes; the boot audit covers 96 BIOS and
255 protected-mode instructions, not all runtime instructions. All eleven
native public-API cases pass in `build/i386-c4-string-util-native`, with unchanged
inputs. Existing replacement/navigation cases also pass in
`build/i386-c4-string-util-editor`.

Normal 8 MiB startup completes all nine commands in 57.32 seconds in
`build/i386-c4-string-util-startup`. Console's logged load span is 2340888 bytes,
1040 above the previous image and 4416 below the unchanged 2345304 cap. However,
the boot log contains ten recoverable raw-heap exhaustion observations, each
requesting 8755 bytes. The cap-only report passes but does not establish zero
pressure. The 8 MiB scanner regression fails after an OutMem rejection during
fixture transfer in `build/i386-c4-string-util-scanner`; this is not a scanner
behavior pass.

The footprint reporter now has `--require-no-allocation-failures`. On the same
actual logs it rejects the candidate in `build/i386-string-util-pressure-red.json`
and accepts the prior zero-pressure image in
`build/i386-string-util-pressure-control.json`. This optional gate applies to
normal boot evidence, not intentionally failing diagnostic allocation probes.
It detects logged failures, not every possible allocation outcome or peak use.

A bulk export-initialization candidate retains all 283 associations and public
bindings while replacing repeated setup calls with local address assignments
and a name-stream loop. The source-level comparison in
`build/i386-console-export-compaction.json` confirms every index/name/function
association is preserved; this is not runtime execution of all exports. The
local-address pattern is already used by MemoryRuntime; it does not require the
unqualified global function-address constant initializer. Bootstrap passes;
the separate cross-build and repeat memory/API/scanner/editor gates remain to
be checked. Do not claim the resource regression resolved from source compaction
alone.


The compact image in `build/i386-c4-string-util-compact-cross` builds and passes
all eleven native utility cases in `build/i386-c4-string-util-compact-native`.
Its Console payload is 2335144 bytes, 5720 smaller than the first candidate.
However, `build/i386-c4-string-util-compact-startup` fails the ordinary 8 MiB gate
with OutMem while compiling SPText. Smaller retained code alone has not solved
the resource/fragmentation regression. Keep this failure visible and do not
promote Console 114 as a replacement for the qualified minimal-profile image.
The helper pre-scan compiler repair is a subsequent candidate; it requires its
own bootstrap, cross-build and repeated API/resource checks.
