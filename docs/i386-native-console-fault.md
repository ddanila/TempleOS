# Native Console compile fault: current evidence

The 16 MiB 486-without-FPU component build in
build/i386-c2-editor-replace-native-build has terminated with failure. It reached
723 functions, logged NativeMousePresentSplit's body completion, then reported
FAULT vector 13 at PC 0x220711 and FAIL native kernel. EditorRuntime was not
built and no export audit passed. Do not leave this job recorded as running or
infer native qualification from earlier progress logs.

The debug log's retained CompilerRuntime base is 0x18F928. Accounting for the
8-byte loader prelude maps the fault into its payload at 0x90DE1, inside
I386ValueClass at offset 0x1C9. The instruction is movzx eax,word [eax], in the
opcode-reading portion of that function. The mapping and input hashes are in
build/i386-c5-console-fault-location.json. This locates the fault; it does not
prove the operand value, invalid IR producer or a root cause.

## Isolated counterexample

The probe tools/probe-i386-mouse-module.py extracts the exact complete
NativeMousePresentSplit body and complete CNativeTextInput, CNativeTerminal,
CNativeRenderScope and CNativeGraphicsScope records from their canonical source
files. It includes the canonical task/text records and uses signatures for the
real helper imports. It does not replace runtime helpers with stub bodies.
The resulting module is compiled, not linked or executed as a mouse test.

build/i386-c5-mouse-compile-isolated passes at 16 MiB on the same no-FPU CPU.
The module bytes and exact generated source are retained. This means the full
failure is not reproduced by that isolated declaration context. Differences in
surrounding definitions, compiler state and preceding work remain hypotheses;
none is established as the cause. No guard that silently treats invalid IR as
an integer type has been added, and mouse logic has not been shortened.

The `--task-validator-body` variant also passes in
build/i386-c5-mouse-compile-validator-body at 16 MiB on 486,-fpu, with unchanged
pinned inputs. It substitutes the complete canonical Kernel/TaskValidate.HC
body for its import and pins that file. Thus the presence of that definition
alone is insufficient to reproduce the fault. This remains compilation-only
evidence; the full Console failure and its root cause are still open.

The combined `--task-validator-body --helper-bodies` variant also passes in
build/i386-c5-mouse-compile-helper-bodies with unchanged inputs. Besides the task
validator, it includes complete canonical NativeTerminalFind,
NativeMouseBackingMatches and NativeDisplayViewMatches bodies, with their real
global types and remaining helper import signatures. DisplayView.HC is pinned.
These additional definitions are still insufficient to reproduce the fault in
isolation. Graphics locking and row presentation remain imports, and the full
preceding Console compile state is absent. No runtime mouse pass is claimed.

The combined `--presentation-bodies --helper-bodies --task-validator-body`
probe passes in build/i386-c5-mouse-compile-direct-bodies with unchanged inputs.
It adds complete canonical NativeMouseRestoreRows, NativeMousePresentRows,
NativeGraphicsTextLock and NativeGraphicsTextUnlock bodies and pins
GraphicsFrame.HC. All direct non-intrinsic helpers of NativeMousePresentSplit
now have bodies in this variant; their own lower-level dependencies remain real
imports. This still does not reproduce the full compile state or execute mouse
presentation. Root cause remains unproven; do not replace the original bodies.

## Diagnostic replay: terminal with captured evidence

The Console-only diagnostic replay has terminated with the same failure in
build/i386-c2-editor-replace-native-debug on the unchanged source/image. It opens
a loopback GDB endpoint and has a watcher that waits for NativeMouseRestoreRows
before attaching a conditional breakpoint at the mapped opcode-read instruction.
If reached with the suspected end-of-address-space operand, the debugger saves
registers, stack and guest RAM to fault-gdb.log and fault-ram.bin in that output
directory. The generated fault.gdb will record the actual runtime-adjusted PC.
The watcher captured registers, stack and the full 16 MiB guest RAM before
detaching; the guest then reported the same vector 13/PC and the runner failed.
The replay and watcher are terminal, not still running.

The earlier blanket host-source freeze is lifted after verifying the actual
replay boundary: the runner compiles embedded source.img files and audits against
the original frozen export directory. Four key embedded files matched host
sources before candidate edits; original image/export hashes are recorded in
build/i386-native-console-debug-snapshot.json. Console-114 string API work uses
a separate build directory and does not change this replay's source or compiler.
Keep the replay image and reference export directory unchanged.

The watcher is /tmp/watch-i386-native-console-fault.py; its log is
/tmp/i386-native-console-fault-watcher.log. Build output is also retained in
/tmp/i386-native-console-debug-build.log. Preserve these captured inputs. This failed debug replay is not a release pass.

The captured operands and fast contract below now identify the pre-scan phase
error. Rerun native component/generation gates after the candidate repair. Directory-context reference
work is independent test-first progress; it does not resolve this C5 failure.
C1–C5 remain incomplete.

## Captured cause and test-first repair

`build/i386-c5-console-fault-capture.json` pins the captured RAM/register/log
artifacts. I386ValueClass receives `ic=0xFFFFFFF7`; adding the opcode offset 8
yields EAX=0xFFFFFFFF at the fault. Its caller is I386FrontendNeedsHelpers
(return PC 0x295F21), not the backend emitter loop. The caller's node local is
0xCC0E48, opcode 0x36 (IC_ADD). The target tree/code union starts at offset 85;
arg2_tree at offset 97 contains 0xFFFFFFF7. The surrounding bytes decode as
machine instructions, not constructed tree links.

The pre-scan executes before the backend's OptPass012 establishes those links.
Reading the recycled union is invalid at that phase. The candidate scans each
listed node's own class/flags and explicit float/conversion opcodes instead.
Operands are themselves list nodes, so detecting floating-point requirements
does not require traversing unconstructed trees. I386ValueClass is unchanged;
no fallback silently assigns a type to invalid IR.

`tools/test-i386-helper-scan-reference.py` compiles the exact production scan,
value classification and complete canonical backend type on the pinned original
x64 system, with canonical opcode metadata. A synthetic pre-optimization integer
node contains stale pointers to a valid F64 node. The old scan incorrectly
requests helpers: mask 60 instead of 63 in
`build/i386-c5-helper-scan-metadata-red`. The fixed scan passes 63 in
`build/i386-c5-helper-scan-green`, including the observed -9 stale pointer, own
F64 class, immediate F64, result-to-F64 flags and F64 result-type cases. Inputs
remain unchanged in each run. The first fixture attempt lacked the private
opcode table and timed out in the original debugger; it is a fixture failure,
not the semantic red gate. Both failed attempts are retained.

This proves the bounded phase-contract repair on x64. Native code generation,
float regressions and full Console/Editor rebuilding still require a fresh
candidate and current-source evidence. C1–C5 remain incomplete.

## Combined build checkpoint (2026-10-16)

The repaired compiler and Console-114 string/export candidate now cross-build
successfully in `build/i386-c5-helper-scan-cross` from commit `2c953e2e`.
The manifest's 1480 source hashes and 24 build-input hashes match the workspace;
both disk image hashes also verify. The matching-source original bootstrap
passes. The kernel is 570800 bytes and the limited boot instruction audit passes
with 96 BIOS and 255 protected-mode instructions.

No boot test ran as part of this cross-build. Native Console/Editor rebuilding,
floating-point regressions and installed generations remain unqualified for the
repair. The combined image also needs fresh API and 8 MiB resource checks; the
preceding string candidate's memory failures remain open.
