# Shared constant folding and type analysis on i386

`Compiler/I386/OptPass012.HC` exposes `I386OptPass012` through the retained
compiler runtime's `code_optimize` service. It executes the shared production
pass on native, control-owned intermediate code. The native parser, complete
optimization pipeline and JIT still require integration.

## Shared code and initialization

`OptPass012Core.HC` contains the existing pass 0/1/2 transformations. Internal type
records and diagnostic reporting arrive through a per-call `COptPass012Services`
record. The x64 `OptPass012` wrapper retains its public entry, allocator and
LexWarn/LexExcept diagnostics. The native wrapper uses the owning heap and resident
exception service. Parser stack helpers, operand type fixups and target-size
queries are shared source files, not separate implementations.

`ICInfo.HC` initializes all 185 opcode descriptors from one shared list. Explicit
initialization avoids the native AOT compiler's unsupported static string-pointer
initializers. The x64 compiler initializes this table in `CmpFillTables`; the
native module initializes it before publishing its services. No compiler call
may run before that initialization. The table is then treated as read-only.

## Ownership and failures

The native entry requires the current control owner, pass 0 through 2 and borrowed
internal types. Invalid setup returns null. The caller supplies valid parser IR,
including well-formed operand stacks, class records and tree links; this internal
pass does not validate arbitrary graphs. It sets `CCF_TARGET_I386`, so the shared
pass preserves portable branch IR and uses four-byte pointer sizes.

The pass allocates `cc->ps` from its control's heap on first use and retains it
for later passes. Full control destruction reclaims it. Per-call type and report
records live on the caller's stack. The diagnostic callback borrows the graph and
must return without mutating or reentering it. Warnings increment `warning_cnt`;
errors increment `error_cnt` and throw `Compiler` after reporting. Failed stack
allocation throws `OutMem` without publishing a stack pointer.

The pass runs with the caller's interrupt state; allocation uses a short protected
section. Failure can leave transformed IR, so recovery must discard or unwind the
failed compilation before starting fresh work. It does not promise transactionally
unchanged IR after a diagnostic or arithmetic exception.

## Retained interfaces and probe

CompilerRuntime ABI 20 is 116 bytes, appending `code_optimize`; its 21 imports are
unchanged. FileRuntime ABI 11 validates this dependency and keeps its 32-byte
record. CompilerProbe ABI 5 is 56 bytes and borrows the kernel's internal-type
array. Its 17 imports are unchanged.

The standalone probe calls the retained service during boot and task execution.
For each of passes 0, 1 and 2 it checks signed multiplication, unsigned division,
F64 addition, remainder, raw XOR and shift, and mixed I64/F64 promotion. It checks
folded values, operand retirement as NOPs, tree links, stack shape and exact heap
reclamation. It also exercises a real U0 dereference warning, a leftover-expression
stack error with `Compiler` unwind, and exhausted-heap stack allocation with
`OutMem` cleanup. These are bounded integration examples, not exhaustive coverage
of every opcode or numerical edge case.

Software F64 evaluation now participates in native constant folding. Cross-host
compilation still folds using x64 arithmetic; existing numerical compatibility
limits, including NaN payload policy, remain. Full native source-to-code execution,
public allocation/task interfaces, self-hosting and strict 386SX/DX verification
remain required by `PLAN.md`.
