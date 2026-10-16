# Original raw output on the native VGA profile

The shared `Kernel/RawOutputCore.HC` retains the complete original RawPutChar:
dollar suppression and quoting, SHOW_DOLLAR, tabs, backspace, newline,
displayable-character filtering, wrapping, scrolling, font bit reversal,
cached pixels and direct hardware writes. The text-mode branch is retained,
but the native boot profile selects BIOS VGA mode 12; text-mode boot is not
qualified by this work. `Kernel/KeyRawOutputCore.HC` retains both complete
original raw key-device handlers, installed at their original 0x60000000
priority between input filtering and console output.

Console 119 appends RawPutChar as its 300th binding. The native adapter saves
and restores interrupt flags through the existing i386 services. Its private
VGA run-level value describes the actual boot mode without claiming a complete
public sys_run_level implementation. The reverse-bit table is initialized at
console startup. A zeroed 38,400-byte raw cache is allocated on first use from
the kernel heap, independently of the calling task's lifetime. The original
renderer then handles all characters, including recursive whitespace output.

## Independent original-system evidence

The fixture in tests/guest/i386-raw-output-reference warms the real renderer
before replacing its cache with a capture buffer. Each capture suspends the
window manager, clears real VGA memory, invokes the public output path, and
reads every hardware plane through the VGA read-map register. It records six
64-bit state fields, the 38,400-byte cache and four 38,400-byte hardware planes.
It also checks document roles, last document entry, raw-state restoration and
exact caller-heap recovery. The 13 cases cover direct glyphs, tabs, backspace,
newline, suppressed dollar commands, doubled dollars, SHOW_DOLLAR, wrapping,
scrolling, a tab at the right edge, extended glyphs, filtered controls and a
direct RawPutChar call outside raw mode.

The pinned original at c26482bb6ad3f80106d28504ec5db3c6a360732c with repair
revision ce055f205fc38536443289fb1cfc73632f6624f4 passes all 13 cases in
build/i386-c4-raw-output-control-reference. Its full-capture hashes and metadata
are frozen in oracle.json and checked by both runners. A fresh pinned rerun
passes in build/i386-c4-raw-output-frozen-reference; the extracted original
passes in build/i386-c4-raw-output-current-reference. All four hardware planes
match the cache exactly. All these completed runs have unchanged inputs.
The native preflight fails on the missing RawPutChar binding in
build/i386-c4-raw-output-red, also with unchanged inputs.

The first reference fixture used a non-HolyC backspace escape; its unexpected
column exposed that fixture error. The corrected fixture uses character 8.
The initial extraction-only bootstrap was invalidated by subsequent source
changes and is not qualification. A fresh complete bootstrap passed. The first
native cross-build rejected an unsupported #undef directive in the adapter
(build/i386-c4-raw-output-cross); the corrected adapter uses a persistent alias
only after defining the original renderer and allocation wrapper.

Static reconstruction in build/i386-raw-output-extraction.json verifies exact
original bytes for the renderer after removing only the interrupt adapter,
both handlers, and the shared VGA/run-level constant groups. The export map
in build/i386-raw-output-export-map.json records all 300 ordered bindings.

The corrected adapter passes the two-generation bootstrap and native cross-build
in build/i386-c4-raw-output-macro-cross, including the 96 BIOS/255 protected-mode
instruction audit. All 13 native captures match the frozen original exactly in
build/i386-c4-raw-output-native (17 commands, 64 MiB). All eight diagnostic cases
now pass in build/i386-c4-raw-output-diagnostic, including the previously failing
unfinished raw dollar command. Both runs preserve their input hashes.

The first 8 MiB startup run completed its behavior checks but failed the
60-second timing target at 62.474 seconds while both fixtures also ran. Its
failure remains recorded in build/i386-c4-raw-output-startup. The subsequent
run after both fixtures exited also failed, at 61.302 seconds, in
build/i386-c4-raw-output-startup-serial. Both completed all nine behavior checks,
including exact VGA restoration, without loading build-only support. The
60-second threshold is unchanged and this regression remains open. A requested
prior-image control was rejected by the harness because its source pins no
longer match; that rejection supplies no timing evidence. A controlled baseline
comparison requires a matching source snapshot, not bypassing the pin check.

These tests do not
qualify the full desktop, arbitrary raw output concurrency, cache allocation
failure, text-mode boot or the complete C1-C5 compatibility inventory.

The broader public task-kill regression passes all nine cases/69 commands
at 64 MiB in build/i386-c4-raw-output-kill, with an unchanged source disk.
This checks existing task behavior after the handler change; it does not
independently exercise first raw-cache allocation from a dying child task.

The matching prior-revision checkout at 9083f83d passes the same 8 MiB gate
in 57.137695 seconds (build/i386-c4-raw-output-pinned-prior-startup). It ran
after the task-kill test with the same older C5 job still active. The corrected
current image remains failing at 61.301742 seconds. This single control does
not identify a cause, but it means the miss cannot be dismissed solely as
fixture concurrency; startup performance needs investigation before this
checkpoint qualifies the minimal profile.
