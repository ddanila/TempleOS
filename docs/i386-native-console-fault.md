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

## Live replay

A new Console-only diagnostic replay is live in
build/i386-c2-editor-replace-native-debug on the unchanged source/image. It opens
a loopback GDB endpoint and has a watcher that waits for NativeMouseRestoreRows
before attaching a conditional breakpoint at the mapped opcode-read instruction.
If reached with the suspected end-of-address-space operand, the debugger saves
registers, stack and guest RAM to fault-gdb.log and fault-ram.bin in that output
directory. The generated fault.gdb will record the actual runtime-adjusted PC.
Those artifacts are pending, not evidence already captured.

The watcher is /tmp/watch-i386-native-console-fault.py; its log is
/tmp/i386-native-console-fault-watcher.log. Build output is also retained in
/tmp/i386-native-console-debug-build.log. Preserve the runtime sources while the
replay runs and poll its actual process/session. Do not restart simply because
an observation times out. This is a debug replay, not a release pass.

Next inspect the captured operands/current backend node if the fault reproduces,
reduce the actual failing state to a fast compiler contract, fix the cause, and
rerun complete native component/generation gates. Directory-context reference
work is independent test-first progress; it does not resolve this C5 failure.
C1–C5 remain incomplete.
