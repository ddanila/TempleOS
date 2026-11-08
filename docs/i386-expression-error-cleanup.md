# Public expression error cleanup

For the tested parse, backend-precondition, and evaluated-expression failures,
the shared `Compiler/PrsExp.HC` now restores the saved graph and trace/host-constant
flags. The normal APIs retain the same exception tags and error counters.

The pre-change normal image leaked 4,584 live bytes per malformed expression,
even after the probe released every reachable graph. The expression's saved
control and trace flag were not restored. Each of the raw/I64/F64 evaluating
wrappers leaked a 56-byte generated code allocation when its call threw. A
throw during a cast's first array-bound evaluation leaked 4,640 bytes and left
the outer compilation context selected. Successful compilation also cleared a
pre-existing host-constant flag.

The parser now frees its owned stack before issuing a second parse diagnostic,
and frees it when a non-Compiler exception propagates. A supplied parser stack
remains caller-owned. The binary wrapper installs its handler before saving a
graph, tracks whether that save succeeded, releases only the temporary graph,
restores the saved graph and the trace/host-constant bits, and then propagates
any captured exception. A secondary cleanup diagnostic does not replace an
already captured exception. Each evaluating wrapper frees generated code in
its catch before automatic HolyC propagation; it does not explicitly throw
from inside that catch.

Run:

```
python3 tools/test-i386-public-expression-errors.py IMAGE --out OUT
python3 tools/test-i386-public-expression.py IMAGE --extended --out SUCCESS_OUT
```

The error contract has nine cases: three malformed expressions, successful
flag preservation, an invalid AOT backend precondition, throws from all three
evaluating wrappers, and a throw during the first dimension of an array cast.
Each row checks the exception tag and error count, saved control chain,
trace/host-constant mask, preserved outer instruction, caller data/code heap
deltas, compile-result presence, and a following successful result 42.
Diagnostics go to a private document which is released before measurement;
pending Adam error jobs are drained. Thus retained diagnostic text is not
mistaken for an orphaned compiler allocation. The probe cleans reachable
frames after recording restoration checks, so a failure cannot pass merely
because the probe repaired it.

Evidence:

- `build/i386-expression-error-baseline-v3/result.json`: eight pre-fix rows,
  including syntax leaks, flag loss, backend context loss and evaluation leaks.
- `build/i386-expression-nested-error-baseline-v2/result.json`: pre-fix nested
  array-bound evaluation failure and 4,640-byte leak.
- `build/i386-expression-error-contract-v2/result.json`: all nine rows pass
  through normal delivered APIs at 64 MiB, with exact counters/tags, restored
  graphs/flags, zero heap deltas, continued execution, one publication,
  unchanged inputs and filesystem checks.
- `build/i386-expression-error-success-v2/result.json`: all previous basic and
  extended normal expression/type/class/function/statement/stream checks pass.
- `build/i386-expression-error-lex8-v2/result.json`: normal lexer regression
  passes at 8 MiB.
- `build/rebuild-test/result.json` and `build/i386-expression-error-cross-v2`:
  two original native rebuilds and the current cross-build/instruction audit.
  All native runtime modules and the flat kernel are byte-identical to the
  preceding publication checkpoint; this change is in the shared source body.
  These checks do not qualify C5's complete native release generations.

ABI versions remain Compiler 101, Console 259 and Memory 41. Source pins and
revision identify this implementation change. The normal expression tests use
64 MiB; no new 8 MiB expression-service or startup-performance claim is made.
Allocator/context-install exhaustion, cancellation/concurrency, richer partial
type/declaration ownership (including later array dimensions), other backend
failure modes, assembly/AOT closure, and full C1–C5 qualification remain open.
Bundled qualification remains 2/686.

`build/i386-expression-error-cross-v2/final-verification-audit.json` verifies
1,833 source pins, 26 build-input pins, images/modules, current bootstrap,
all component receipts and input pins, pre-fix leak observations, exact prior
success records, the unchanged sixteen native modules/flat kernel, ABI layouts
and the 2/686 inventory count. It records an explicit immutable base revision
and the remaining qualification limits.


## Partial array dimensions (2026-11-08)

The next failure was ownership inside the shared array-dimension parser. On
`build/i386-expression-error-cross-v2/kernel.img`, throwing while evaluating the
second or third bound retained 32 or 64 bytes. A missing closing bracket or a
negative later bound retained 32 bytes. Direct PrsType calls also returned an
exception with a partially populated dimension root. The actual observations,
including successful controls, are in `build/i386-array-partial-baseline-v2`.

CPrsTypeServices now appends an optional release callback. The normal host sets
it to Free: one handler owns partial dimensions, unlinks and frees every node,
resets the root to next=NULL/cnt=0/total_cnt=1, and automatically propagates the
original exception. Success transfers the complete list to the caller. A pending
allocation is tracked separately until it is linked. The parsing algorithm,
bound evaluation, size diagnostics and count propagation remain shared.

The private frontend explicitly sets release=NULL. Its allocations are already
registered with the parser controller, which retains partial allocations until
its lifetime ends. This path uses the same parser body without another exception
record. The diagnostic expression service initializer also explicitly selects
this lifetime policy; declaration probes inherit it. Release callbacks must
match allocation and must neither allocate nor throw for a live node.

An initial unconditional-handler implementation failed the existing 16 MiB
exhaustion probe: allocating the extra handler in an already exhausted private
arena caused HEAP EXHAUSTED and PARSER TOKEN PROBE failure. That evidence remains
in `build/i386-array-partial-diagnostic16-v1`. The revised ownership policy keeps
the existing private arena lifetime rather than allocating another handler there.
The first expanded fixture also used an unsupported native ternary expression;
its failed receipt remains in `build/i386-array-partial-contract-v1`.
The later initializer check in `build/i386-array-partial-cross-v3` rejected
`NULL` in the minimal probe import context; using its existing zero-pointer
convention fixes that source error. This failed cross-build is also retained.

Run:

```
python3 tools/test-i386-public-expression-errors.py IMAGE --array-partials --out OUT
```

This retains the nine original error/control rows and adds four expression
failures plus seven direct type cases. It checks throws after one/two dimensions,
missing brackets and negative later sizes, exact exception/error counts, root
reset before any probe cleanup, preserved caller graph/flags, zero heap deltas,
and continued result 42. Successful two-dimensional, unspecified-first-bound,
and no-array cases verify counts, type identity and caller ownership. Reachable
old partial lists are freed only after failure observations, so baseline cleanup
cannot conceal a leak or incorrectly retained root.

Compiler ABI is 102 and Console ABI is 260 because the embedded private service
layout changed; Memory remains 41. Public export names and order remain 688 with
22 data-mask words. The isolated 249-case code-generation corpus supplies handler
symbol test doubles for successful array parsing only; actual throwing/unwinding
uses the normal delivered services and real task exception runtime.

Current-source evidence:

- `build/i386-array-partial-contract-v4/result.json`: nine existing rows plus
  four partial-array expression rows and seven direct type rows.
- `build/i386-array-partial-success-v4/result.json`: all previous basic and ten
  extended expression/type/class/function/statement/execution/stream groups.
- `build/i386-array-partial-lex8-v4/result.json`: normal 8 MiB lexer regression.
- `build/i386-array-partial-functions-v4/result.json`: 249 audited function
  cases, including five deliberate faults, on the 8 MiB TCG486 runner.
- `build/i386-array-partial-welcome8-v4/guest/screen-oracle.json` and
  `build/i386-array-partial-diagnostic16-v4/guest/screen-oracle.json`: complete
  307,200-pixel TCG486 welcome frames; both diagnostic phases include the token,
  helper-frame fault, program and backend-literal reservation probes.
- `build/rebuild-test/result.json`: two original bootstrap generations;
  `build/i386-array-partial-cross-v4/result.json`: current full cross-build and
  instruction audit. These are not C5 complete native release generations.

Final receipts and source/image pins are indexed by
`build/i386-array-partial-cross-v4/final-verification-audit.json`. This narrows the
later-array-dimension ownership gap. It does not qualify allocator/handler-install
failure in public services, cancellation/concurrency, broader type/declaration
ownership, other backend failures, assembly/AOT closure, full desktop/apps or
native release generations. Qualification remains 2/686 and C1–C5 remain open.


## Declaration members and default code (2026-11-08)

On the preceding committed normal image, a member allocated before a failed type
parse retained 136 bytes. Rejecting a duplicate array member retained 168 bytes;
a throw while executing compiled function-default code retained 56 bytes. The
outer instruction graph survived, but declaration-owned flags and lexer snapshots
were left changed. `build/i386-declaration-error-baseline-v3` records twelve
actual normal PrsVarLst failure/control cases with a pre-existing caller snapshot.
It also records a throwing MemberInsert warning: the pending member became
visible in the name tree before being appended to the owned member list.

CPrsDeclarationServices appends optional members_delete. The normal host uses
MemberLstDel; the shared declaration wrapper tracks an unlinked member and a
compiled default-value block until their respective ownership transfers. On
failure it releases those temporaries, drops only snapshots acquired by this
call, restores incoming DONT_MAKE_RES/CLASS_DOL_OFFSET/HAS_MISC_DATA bits, and
propagates the same exception automatically. Already registered members remain
in the class and are released with that owner. It does not roll back the entire
class or publish a failed pending member. The same parsing body runs for the
private controller-arena environment with members_delete=NULL, without an extra
exception record; the diagnostic service initializer explicitly selects it too.
Cleanup callbacks must not throw for live allocations or snapshots.

MemberInsert now performs duplicate-type warnings before changing either index
or the owned list. Its member_add ownership contract transfers only on successful
return, so a throwing diagnostic leaves the pending member with its caller.
Normal parser loading now delivers the shared symbol/member deletion helpers in
the declaration stage, before the new cleanup callback references them. The
following symbol stage reuses them; the twelve-stage publication protocol and
688 public exports are unchanged. Compiler ABI is 103, Console 261, Memory 41.

Run:

```
python3 tools/test-i386-public-expression-errors.py IMAGE --array-partials --declarations --out OUT
```

The twelve declaration rows cover first/later-bound throws, bad brackets,
duplicate array members, missing class closure, throwing and malformed function
defaults, throwing metadata, nested-union failure and successful multidimensional,
default-value and metadata controls. They check exact tags/counters, caller
snapshot/flag/graph preservation, retained member counts and index/list agreement,
zero heap deltas after releasing the registered owner, and continued result 42.
The insertion row checks both indexes/list remain unchanged on a warning throw,
with caller cleanup performed only after observation. The nine original error
rows and eleven array rows remain required in the same normal session.

The first fixture incorrectly equated the lexer-resolved I64 descriptor with
cmp.internal_types[RT_I64]. The recorded type detail on the unchanged baseline
shows the named descriptor is a different pointer, with the correct I64 raw type
and 2-by-3 dimensions. The final control compares against the input's own named
lookup, and records both identities; it does not discard the type/shape check.
The first delivered image also exposed a real missing loader dependency at
PrsDeclarationHost: MemberLstDel was still in the next stage. Its failed normal
API receipts remain in `build/i386-declaration-error-contract-v1` and
`build/i386-declaration-error-success-v1`; the dependency is moved earlier.

Final source/image/component evidence is indexed by
`build/i386-declaration-error-cross-v2/final-verification-audit.json`: all 33 normal
failure/control rows, prior success records, 8 MiB lexer, 249-case corpus, two
original bootstrap generations, cross-build/instruction audit, full 8/16 MiB TCG
welcome frames and both diagnostic phases. The normal declaration contract uses
64 MiB; the full-frame checks do not qualify startup performance or complete
native C5 generations.

The initial bootstrap invocation accidentally reused build/rebuild-test after a
patch-script assertion stopped before its rename. The prior receipt survives
exactly in the preceding checkpoint's function-bootstrap-input.json; its native
cross-build and API evidence remain independent. Both prior second-generation
binaries were recovered byte-for-byte from its retained compiler ISO and checked
against that receipt; the first-generation binaries were not recovered. The
mistake is documented in
`build/i386-declaration-error-bootstrap-v1-preservation`. tools/test-rebuild.py now
refuses an existing output directory before modifying it; a real refusal check
verifies every existing file's size/mtime and receipt hash stay unchanged. Rename
the old directory to a unique evidence name before a fresh bootstrap.

Public allocator/handler-install exhaustion, cancellation/concurrency, anonymous
function/type-join ownership, broader symbol/header rollback, other backend errors,
assembly/AOT, full desktop/apps and native release qualification remain open.
These component corrections leave full C1–C5 qualification at 2/686.
