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

## Normal public optimizer delivery

Console 256 adds the normal `OptPass012(CCmpCtrl *)` entry declared in
`Kernel/I386/PublicCompiler.HH`. That header includes the canonical IR opcode
and metadata definitions in `CompilerA.HH`, alongside the public control/graph
interfaces. The complete original-style public wrapper and shared
`OptPass012Core.HC` run from `Compiler/I386/PublicOptSupport.HC`, compiled in Adam
on first use. This path uses ordinary public allocations and standard controls;
it does not cast a public control to the private arena-owned optimizer control.

`ConsoleInit` borrows the existing kernel canonical type pointers into
`cmp.internal_types`. It creates no duplicate scalar records or hash table.
The type registry already has kernel lifetime. Other compiler-global tables and
complete normal parser/backend delivery remain separate work.

The optimizer source module loads the complete opcode metadata, stack helpers,
type/size/branch transformations and original diagnostic helpers. Metadata is
initialized before publishing its function pointer. Its cache shares the existing
system-service context and protected symbol table with the JIT/resolver services,
while loading independently. The loader waits/rechecks Adam, restores its hash
table on exit, and throws `OptLoad` if publication did not complete. First-use
retry, concurrency and cancellation are not qualified by the current contract.

`ICDetachCore.HC`, `OptFreeCore.HC` and `ICDiagnosticsCore.HC` extract the existing
complete helper bodies. The normal compiler includes these same files. The
extraction audit verifies identical bodies (apart from one final blank line).
`OptPass012.HC` only gains a configurable implementation name; the optimizer core
algorithm is unchanged. Console appends one function after the existing 677
exports and keeps all data masks and context-data index 671 unchanged.
CompilerRuntime remains 95; the strict builder requires the new function and
Console version 256.

`tools/test-i386-public-optimizer.py` compares sixteen integer/F64 expression
graphs through all three passes against the pinned original complete optimizer
and its original helpers/metadata. It checks exact opcode/type/value triples,
full stack allocation/reuse, canonical type identity and caller data/code heap
recovery. The native fixture imports only the normal public compiler header and
constructs IR with public graph services; it loads no optimizer replacement.

The original capture `build/i386-public-opt-original-v3` and native 16 MiB capture
`build/i386-public-opt-native16-v2` pass all eighteen assertions and the same
48-word trace. Native caller data/code growth is zero, with one system publication,
normal arithmetic pixels, sole fixture addition and volume validation. Input
hashes remain unchanged. The earlier native failure is retained: its header
omitted opcode definitions and rejected `IC_ADD` before optimizer execution.
The fixed header is preserved in the current image and verified by the native
contract. The source modules and flat kernel are identical across that header
fix; the logical-volume audit finds only PublicCompiler.HH changed.

The full source compiler regression now imports this normal public optimizer
instead of defining a replacement `OptPass012`. Its parser and backend adapter
remain source-loaded diagnostics; this transition does not qualify normal
`COCCompile`, `CmpJoin`, parsing, whole compiler files or a complete workflow.

Verified commands:

```
python3 tools/test-i386-public-optimizer.py --out build/i386-public-opt-original-v3
python3 tools/test-i386-public-optimizer.py build/i386-public-opt-cross-v3/kernel.img --reference build/i386-public-opt-original-v3 --ram-mib 16 --out build/i386-public-opt-native16-v2
python3 tools/test-i386-public-expression-source.py build/i386-public-opt-cross-v3/kernel.img --compiler-stream --out build/i386-public-opt-compiler-source-v2
```

The last command passes all 25 publication stages and subsequent lexer, graph,
expression/type/runtime/lifetime/class/function/statement/ExeCmdLine/stream
probes through the delivered optimizer. Its debug log records exactly one
`PUBLIC OPT loaded` publication. The preserved generated parts contain no
source replacement of OptPass012. Input and volume checks pass.

Both current-source original compiler/kernel rebuild generations and the full
cross-build pass. Resolver-progress and JIT/AOT contracts pass on the preceding
candidate with identical native binaries; that candidate differs only in the
public header whose correction is exercised by the current optimizer contracts.
Its 8/16 MiB TCG boots match every welcome/prompt pixel and the 16 MiB diagnostic
boot completes both compiler phases and exact ownership markers. Timings are
234.47 and 435.81 seconds respectively. The current fixed-header image also
passes the 8 MiB KVM startup/source preflight. The audits retain this distinction;
these are not new full C5 generation/reproducibility/performance qualifications.

Normal COCCompile/LexStmt2Bin/parser delivery, compiler-global initialization
beyond the canonical type pointers, complete diagnostic behavior, allocation
failure, first-use recovery/concurrency/cancellation, and the full application
inventory remain open. No workflow or C1–C5 milestone count advances.
