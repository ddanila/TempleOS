# Shared branch optimization on native i386

The retained compiler runtime now exposes `code_branch(heap, cc, node)` to run
TempleOS's production `OptBrZero` and `OptBrNotZero` transformations on native
owned intermediate code. This connects the branch optimizer to the instruction
retirement and control-unwind machinery; it does not yet supply a complete native
parser, optimization pipeline or JIT.

## Shared implementation and allocation policy

`Compiler/OptBranch.HC` contains the existing branch transformations, extracted
from `OptLib.HC`. `OptCode.HC` contains their shared navigation, forwarding and
NOP helpers. The x86-64 compiler includes both files and retains its existing
allocation policy. The transformations are unchanged apart from passing the
compiler control to `OptFree`.

`OptFree` now takes `(cc, node)` throughout the parser and optimizer, including
`OptIC4`'s callers. The native implementation in `Compiler/I386/OptBranch.HC`
uses that control's heap and `I386ICRetire`; the x86-64 implementation still
unlinks and calls `Free`. Native `COCMiscNew` uses the control's owned allocation
registry and throws `OutMem` if allocation fails. The containing native module
must supply the `throw` import or implementation before including this file.

The public entry checks the current owner, allocation identity and branch opcode.
Invalid entries return null without mutation. Its input must otherwise be a
valid parser-produced graph with live tree links and class metadata. This is
compiler-internal code, not a validator for arbitrary or corrupted IR.

Retired predicates and negations keep their fields and old links, so recursive
rewrites can still follow borrowed tree references. Completed graph discard and
full control destruction use the existing retirement collection rules. Rewrites
run with the caller's interrupt state; native allocation/removal operations use
short interrupt-protected sections. The optimizer does not yield.

## Failure and recovery

Short-circuit transformations can retire a predicate before allocating a new
fall-through label. Allocation failure therefore leaves a partially rewritten,
but still owned, graph. Catch `OutMem` at the compilation boundary, discard or
unwind that graph, and start a fresh compilation. Retrying the same partially
rewritten node is unsupported. Unwind walks allocation ownership independently
of queue views and reclaims both live and retired records.

The standalone probe exercises exactly this failure: it builds an OR/zero branch,
registers a native exception frame, fills every free heap span, and calls the
retained optimizer. After catching `OutMem`, it frees the filler allocations and
unwinds to the enclosing compiler control. A new child then performs the rewrite
successfully. Both boot and task phases check exact heap counts, preserved outer
control/input, active-control counts and interrupt state.

## Interface and verification

CompilerRuntime ABI 19 is 112 bytes, appending `code_branch` to ABI 18.
FileRuntime ABI 10 validates the new compiler contract; its own record remains
32 bytes. The compiler module imports the resident `throw` service in addition
to its previous 20 imports. CompilerProbe keeps its 52-byte ABI 4 record and now
imports heap allocation as well as release, for 17 imports. All modules are
rebuilt together; the loader checks versions, sizes and service addresses.

The task-symbol fixture exercises 136 rewrites across enabled/disabled IF:
96 comparison/negation cases, eight AND/OR short-circuit cases and 32 carry/bit
intrinsic cases. It checks opcode, target and tree propagation, queue links,
retired-node readability, invalid-entry rejection and exact reclamation between
cases. The fixture reserves 384 KiB for the loaded stage and begins its 64 KiB
arena at physical 0x70000. This test-only placement leaves the runner stack at
0x90000 and does not change the standalone kernel reservation.

Verification results and current artifact measurements are recorded in
[port progress](port-progress.md). QEMU/486 execution and instruction audits remain
development evidence; strict 386SX/DX acceptance remains open.

## Remaining integration

The native runtime now executes shared branch transformations, but the complete
parser and optimizer passes still need their public allocation, error, symbol,
formatting and backend dependencies connected. Other temporary IR and payload
allocation paths still require ownership routing. Native command compilation,
execution, editing and compiler/kernel self-hosting remain required by PLAN.md.
