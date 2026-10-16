# Compact immediate stack words

CompilerRuntime 73 uses PUSH imm8 when sign extension reproduces the exact
32-bit word (0..127 or 0xFFFFFF80..0xFFFFFFFF), otherwise PUSH imm32. The shared
backend and expression emitter apply this independently to each half of an I64
literal, preserving high-word/low-word order, stack depth and flags. F64 literals
in the backend preserve their raw binary64 bits. Label/data-address relocation
paths are unchanged. Constant folding precedes both output-sizing passes.

The emitter probe executes all 64 pairs from eight independent boundary words:
0, 127, 128, 0xFFFFFF7F, 0xFFFFFF80, 0xFFFFFFFF, 0x80000000 and 0x7FFFFFFF.
It checks exact instruction bytes, mixed instruction lengths, measured capacity,
full EDX:EAX results and allocation recovery. Both native diagnostic phases must
report completion (128 total executions). The existing pressure/unwind probe is
unchanged. The native diagnostic runner now requires this evidence.

The initial expression suite passes all nine cases with instruction audit in
build/i386-c4-drive-device-delete-push-expressions. The first cross-build rejects
the new probe's unsupported local aggregate initializer; explicit assignments
correct it. The first function suite stops at a pre-existing unresolved
I386HeapSize dependency in the included frame helpers. Its fixture now includes
the complete portable heap implementation; no frame assertions are removed.
That failure is preserved in ...push-functions-missing-heap. Adding the full
heap dependency also exceeds the fixture's old 128 KiB aggregate buffer. The
run was deliberately stopped and preserved in ...push-functions-buffer-limit;
the fixture now owns 1 MiB and checks capacity before appending each record.
An initial bounds-check edit accidentally referenced the wrong size variable in
the module fixture and failed during original guest parsing; ...push-functions-bound-typo
preserves that run. The corrected check uses the module's actual size.

Both bootstrap generations and the first complete compact-code cross-build pass in
build/i386-c4-drive-device-delete-push-fixed-cross, with 1506 source/24 build-input
hashes unchanged. Versus the direct-table candidate, ConsoleRuntime shrinks by
286080 bytes and CompilerRuntime by 227202 bytes. The unchanged 8 MiB gate
passes all nine checks in ...push-startup, startup 54.195792 seconds, with all
four execution inputs unchanged and no build provider loaded. C5 was briefly
paused for that timing run and resumed in the launcher's finally block.
All 245 standalone function cases pass with instruction audit in
...push-functions. Their complete heap dependency also enlarges the aggregate
runner beyond its old 128 KiB BIOS transfer. The function-only harness now loads
384 KiB below physical 0x70000, leaving its ordinary stack at 0x90000; the
production boot path and memory limits are unchanged. The transfer-limit failure
is preserved in ...push-functions-transfer-limit. The full 16 MiB gate passes in ...push-diagnostics: startup 251.620727 seconds,
128 push-word executions, both memory-preservation phases, 22 publication and
28 program cases, and all nine interactive checks. These compiler checks use
the image before the subsequent Console data-binding correction. The prior C5 rebuild remains pinned to CompilerRuntime 72 and cannot
qualify this source epoch. The deferred parser-storage experiment is not included.

The final binding correction rebuild is ...drive-device-delete-binding-cross.
Its CompilerRuntime and CompilerProbe modules are byte-identical to the compact
candidate above; only ConsoleRuntime changes. The final 8 MiB gate passes at
56.954345 seconds with all nine checks and unchanged inputs. The final 16 MiB
regression is running in ...drive-device-delete-final-diagnostics.
