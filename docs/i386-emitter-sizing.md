# Count output before allocating the native emitter buffer

The C5 selected-module run in `build/i386-c5-drive-lock-native-build` fails
while emitting the function whose last start record is DocRecalc. The preserved
allocation audit records a 131072-byte request, 13911464 bytes used out of
14101504, 76702 live allocations and a largest free payload of 117144 bytes.
The source-name diagnostic names StrIMatchCore.HC, which is not sufficient to
identify the active emitted function. In that run's reference Console module,
DocRecalc starts at 1655680 and the next export, StrIMatch, at 1757816: a
102136-byte interval. This interval motivates a pressure regression; it is not
an independent exact function-size measurement.

The shared i386 backend previously wrote the entire function during both
passes. Pass zero establishes label offsets, and pass one resolves branches.
The ordinary byte writer doubled capacity on growth, so crossing 65536 bytes
requested a new 131072-byte buffer while retaining the old buffer until copying
finished. The failing run cannot satisfy that request.

The first backend pass now advances the checked byte count without allocating
or writing an output buffer. The second pass sets the measured size as the
exact reserve bound, resets the count, and emits the complete original target
instruction stream. Its final count must equal the measurement. Inline assembly
still validates both passes; its data patches occur only in pass one. Literal
pools, switch tables, branch offsets, relocation records and all function IR
remain part of the complete production pipeline.

Ordinary unplanned byte writers retain their existing geometric growth policy.
The reserve callback still either supplies the required capacity or throws;
failure preserves the prior buffer and count. Owner deletion and compiler
unwind still release the same owned output record and buffer. The added output
state changes CompilerRuntime's interface version from 71 to 72.

## Regression scope

The native emitter probe retains its 64 execution rounds, growth boundaries,
IR-lifetime checks, allocation exhaustion, retry, malformed capacity and full
unwind recovery. It also reserves a 117144-byte hole before filling the arena,
then frees only that hole. Measurement of a 102136-byte output must allocate
nothing. Emission must allocate exactly 102136 bytes, preserve every byte and
reject an extra byte without changing the count or capacity. The ordinary
cleanup then requires exact heap and allocation recovery. Both compiler probe
phases execute this case. Existing backend cases additionally require that a
successful newly created output has exact capacity and no measuring/planning
state left over.

The two-generation original bootstrap and
`build/i386-c5-emitter-measure-cross` pass, including the bounded boot
instruction audit. Its source audit matches all 1503 source and 24 build-input
hashes. Independent comparison against the preceding cross-build finds ten
unchanged modules byte for byte. ConsoleRuntime differs only in one byte,
FileRuntime in two bytes and Kernel in one byte: each is the interface version
71 changing to 72. Their sizes are unchanged. CompilerRuntime grows by 1804
bytes and CompilerProbe by 7063 bytes. The complete comparison is saved in
`module-comparison.json`. The isolated normal 8 MiB regression passes in
`build/i386-c5-emitter-measure-startup`: 55.579832 seconds,
all nine commands, exact VGA restoration, no Build provider and unchanged
execution inputs. The full 16 MiB regression passes in
`build/i386-c5-emitter-measure-diagnostics`: 233.020640-second
diagnostic startup, both exact-capacity emitter phases, all 32 backend cases,
22 publication/28 program-publication cases, preserved live memory and all nine
interactive checks. `emitter-audit.json` verifies the markers and unchanged
execution inputs. This run overlapped the C5 build and is correctness evidence,
not an isolated throughput comparison. The recent
RedSea free-list contract passes all 32 cases/35 commands through the new
native compiler in `build/i386-c5-emitter-measure-free-list`, with unchanged
execution inputs and the exact delivered fixture. The real C5
selected-module build and two complete native generations remain unqualified;
a synthetic allocation case alone cannot establish those outcomes.


The selected-module build was launched in
`build/i386-c5-emitter-measure-native-build`, at 16 MiB on TCG 486,-fpu.
Its launcher PID is recorded beside the directory and its input boundary pins
all source/build hashes, host runners and the immutable starting disk in
`build/i386-c5-emitter-measure-native-input-boundary.json`. ConsoleRuntime and
EditorRuntime are selected. The old failure artifacts remain intact; this is
an independent run, not a resumed or reclassified result.


### Terminal native build result and compact-push retry (2026-10-16)

The CompilerRuntime 72 run in build/i386-c5-emitter-measure-native-build now
terminates with failure. During ConsoleRuntime compilation, StrIMatchCore.HC
requests 0x19233 bytes with a largest available span of 0x14000. The guest reports
PARSER CODE ALLOCATION REJECT, then BUILD MODULE REJECT with OutMem. The runner
records result=fail after cleanup; EditorRuntime is not reached. This is the
0bed4c3a source epoch and does not test CompilerRuntime 73's compact pushes.

A fresh run in build/i386-c5-block-table-native-build uses the image from
build/i386-c4-block-table-cross: CompilerRuntime 73, ConsoleRuntime 123 and
FileRuntime 59. It selects the same ConsoleRuntime/EditorRuntime builds at
16 MiB on TCG 486,-fpu with a 14400-second command limit. Its input-audit.json
pins commit 66b4a08e, the immutable image/manifest and host runners. This run
now terminates with a command timeout during the first ConsoleRuntime build.
The last function-start marker is `NativeWinToTop`, followed by backend/link
progress. No ConsoleRuntime completion or EditorRuntime qualification is
recorded. Several isolated timing checks paused the launcher and guest together;
the wall-clock command deadline includes those pauses. This is a timeout, not
the previous allocation failure, and neither complete native generation is
qualified. Preserve the working disk and logs in the failed run directory.
