# Native top-level command compilation

CompilerRuntime ABI 33 (192 bytes) adds `command`. It compiles one top-level
statement from an active retained frontend and returns registered executable code,
or null when a declaration produces no top-level code. The output type is reported
through `raw_type`; a no-code result reports `RT_U0`. Errors throw and require
control unwind. The caller reads the first token before entering its command loop.

The entry uses the complete shared statement parser. A single input stream may
define functions and globals, execute calls and assignments, and use control flow.
Definitions remain available to subsequent commands in that same environment.
Parsing takes place with global scope; only after parsing does the native adapter
add an empty function frame for code generation. Declarations inside top-level
blocks therefore retain the shared parser's normal scope.

## Results, execution and ownership

The command adapter saves and restores the caller's IR view, pass and AOT/misc-data
state. It clears the last statement's unused-result flag, following `LexStmt2Bin`.
The backend now handles `IC_RETURN_VAL2` according to its shared zero-operand
definition: preserve the existing result registers rather than pop a nonexistent
evaluation operand. A used `IC_END_EXP` pops the value into EDX:EAX before discarding
its evaluation slot. Integer and F64 results keep their native raw-bit convention.

The returned code uses the existing declaration-service `execute` and `release`
providers. This keeps execution under the same ownership checks as other retained
frontend outputs. The caller controls `CCF_JUST_LOAD`: compile declarations and
statements, skip statement execution, then release temporary outputs. Initializer
evaluation during declaration parsing still occurs, as in the original load path.

Multiple command outputs can remain live together. Returned literal pointers
remain valid only while their owning output remains live; the execution provider
marks results pointing into that output's literal pool. Functions, globals and
static storage belong to the compiler control, not to an individual command output.
Releasing a command's temporary code does not remove those definitions. All of
them expire when the control is unwound.

This is not transactional execution: earlier executed statements may have side
effects before a later parse error. The caller must unwind failed compiler state.
Publishing code and data into a longer-lived program/task scope remains necessary
for an interactive session that preserves previous definitions after errors.

## Verification and remaining integration

The native command probe runs 16 cases during boot and again from the worker task.
It checks mixed declarations/execution, loops, a top-level block, arrays, calls and
recursion, integer/F64 results, literal lifetime, partial-source failure, invalid
top-level return, malformed expressions, two retained outputs and load-only mode.
Every command preserves a pre-existing caller IR node. Full unwind restores exact
heap counts, task references, active controls, exception state and IF.

Run:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
python3 tools/test-i386.py --functions
python3 tools/test-i386.py --float
```

The keyboard console is not yet connected to this compiler entry. Durable code/data
publication, answer formatting/public task integration, stream/compile-time
generators, full assembler/try providers, document editing and native self-hosting
remain required. QEMU/486 checks do not establish strict 386SX/DX acceptance.
