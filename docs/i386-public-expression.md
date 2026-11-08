# Public expression compiler integration

## Normal delivery checkpoint (2026-11-08)

Console 259 provides normal `LexExpression`, `LexExpressionI64`,
`LexExpressionF64`, `LexExpression2Bin`, `IsLexExpression2Bin`, and the lexer's
`PrsStreamBlk` callback. `PublicExpression.HH` also supplies the required normal
lexer declarations. Initial-console, root/user, and Adam prompt declarations
expose these entry points without diagnostic source loading.

The first call loads twelve ordered `PublicPrs*.HC` stages in Adam's existing
system namespace, after the normal lexer and optimizer. The stages include the
actual shared expression, type, declaration, class/function, statement,
execution, and stream bodies. They borrow canonical runtime types and initialize
only missing assembler lookup and binary precedence tables. The original
compiler uses the same bodies with default implementation-name hooks. Shared
statement compilation, execution, and base-class lookup were extracted into
includes without changing their bodies.

The six callback slots remain null until the final publication. Readiness is
assigned last; completed stage numbers let a later call resume a failed load.
Every load restores Adam's original hash table on success or exception. Loaded
code/metadata have system lifetime; expression controllers and returned code
keep their existing public allocation/ownership contracts. Earlier export
ordinals remain unchanged: six function exports extend the prior 682-entry
prefix to 688, within the existing 22-word data-kind mask. Compiler 101 and
Memory 41 are unchanged.

Run on a current full native image:

```
python3 tools/test-i386-public-expression.py IMAGE --extended --out OUT
python3 tools/test-i386-public-parser-retry.py IMAGE --out RETRY_OUT
```

The first command checks lazy, exactly-once publication, nine basic executable
expressions, five Boolean binary-wrapper/ownership checks, graph mask 63, six
type checks, eleven runtime expression cases, lifetime mask 15, eight class
checks, seven function cases, ten statement cases, sixteen execution checks,
and nine stream cases. It checks all exported records, final arithmetic pixels,
source/input identity, and filesystem integrity. No replacement parser or lexer
is injected by this command.

The retry test changes only a disposable image copy. It makes stage 11 throw,
checks stage resume, all six unpublished callbacks, namespace restoration and
exact caller heap recovery, restores the original stage bytes/attributes,
then requires successful execution and reuse with one publication. All thirteen
records must equal one. Only the added fixture and the restored stage's date
may differ from the original tree; reachable extents and allocation bitmap
must agree. Its catch releases the controller and propagates automatically,
as required by original HolyC semantics.

Current evidence:

- `build/i386-normal-parser-contract-v4/result.json`: normal APIs and all ten
  extended groups pass, one parser publication, unchanged inputs.
- `build/i386-normal-parser-retry-final-v4/result.json`: all thirteen recovery
  records pass, restored stage bytes/attributes and filesystem checks.
- `build/i386-normal-parser-source-regression-v4/result.json`: independent
  25-stage diagnostic lexer/parser suite with canonical types also passes.
- `build/i386-normal-parser-lex8-v4/result.json`: normal 24-case lexer contract
  passes at 8 MiB.
- `build/i386-normal-parser-welcome8-full-v4/guest/screen-oracle.json` and
  `build/i386-normal-parser-diagnostic16-v4/guest/screen-oracle.json`: all
  307,200 welcome pixels pass in TCG; the diagnostic run completes both phases.
- `build/rebuild-test/result.json` and `build/i386-normal-parser-cross-v4`:
  two original native rebuilds, current-source cross-build, instruction audit.
  These are not the complete native i386 release generations required by C5.

The earlier expression baseline rejected the fixture's first `Lex(cc)` call;
it did not isolate expression publication. The old-image probe in
`build/i386-normal-expression-isolated-baseline-v1/rejection-audit.json`
supplies only existing lexer declarations and verifies rejection at the direct
`LexExpression` call. Its runner expected a different diagnostic string;
the original failing receipt and actual guest log are preserved separately.
The short welcome harness in `build/i386-normal-parser-welcome8-v4` reached its
180-second deadline during startup. The longer full-image boot check passes;
no startup performance qualification is claimed here.

Full compiler/assembly/AOT closure, broader expression-error and backend-failure
cleanup, cancellation/concurrency, and complete application/desktop/release
qualification remain open. The source stages retain explicit unresolved
assembly/AOT services; this checkpoint does not qualify those paths. Normal
expression functionality is tested at 64 MiB; 8 MiB evidence covers startup
and the lexer, not the complete expression service. Bundled qualification
remains 2/686.


## Error cleanup checkpoint (2026-11-08)

`docs/i386-expression-error-cleanup.md` records normal parse/evaluation failure
cleanup, saved graph and trace/host-constant restoration, nine exact error
rows with zero heap deltas, and the preserved successful-expression suite.
The implementation remains in the shared body and preserves tested exception
codes/counters. The older broad error-cleanup gap above is narrowed by those
specific cases; exhaustion, cancellation, richer partial type ownership and
other backend failure modes remain unqualified.

## Earlier integration evidence

The following paragraphs record earlier diagnostic checkpoints. Their normal
delivery gaps are superseded only to the tested extent described above; their
remaining full-compiler and C1–C5 gaps remain open.

The actual original public LexExpression, LexExpressionI64 and LexExpressionF64
APIs pass the reusable contract in tests/guest/i386-public-expression/Contract.HC.
Nine expressions cover integer arithmetic, a full-width literal, unary and
parenthesized operations, comparison, logical negation, float-to-integer and
integer-to-float conversion, and floating arithmetic. Each case also checks the
final semicolon token and zero error/warning counts. Result allocations stay
alive until guest shutdown. The host compares executable results, not merely
published functions or generated bytes.

Run python3 tools/test-i386-public-expression.py --out OUT for the original,
or pass a native disk before --out. The formal original-v2 result passes all
nine state/value pairs. The normal pre-change native image rejects Lex in the
first case helper (baseline-v1, line 6). Independent audits verify current
inputs, restored original source, exact fixtures, fixture-only native volume
changes and unchanged boot bytes.

The full shared PrsExp publication investigation retains every body, including
LexExpression2Bin and its real compilation calls. The v1 source-loaded native
probe rejects the missing intermediate_code_table; v2 supplies and initializes
the complete original ICInfo table, then rejects Bsf in PrsExpressionCore.
Although the backend implements Bsf/Bsr, the normal user intrinsic header omitted
their declarations. The current change makes it include the existing canonical
Bits header. On the revised normal image, v3 passes the scan call and reaches
missing HashAddAfter in PrsHostHashAfter (PrsExp line 29). The insertion
contract passes mask 255 on the original and revised normal native image. V4
passes HashAddAfter and reaches missing Call at PrsExp line 173. The public Call contract now passes mask 255 on original and
normal native images; v5 publishes the complete unchanged PrsExp source and
passes all 24 token checks. See docs/i386-hash-add-after.md and
docs/i386-call.md.

These publication probes are diagnostics, not delivered expression compilation.
PrsType, COCCompile and PrsStreamBlk still require real integration. The v6
prototype additionally publishes the complete optimizer and diagnostic printers,
then fails in the canonical type-record stage before graph execution. V7 splits
that stage and proves the data declaration is rejected before its constructor.
A minimized extern/aggregate reproducer identifies completed-alias publication
as the cause. The patched loader-v8 publishes all 17 stages and passes the 24 token cases,
then rejects an unsupported ternary expression in the diagnostic fixture.
Loader-v9 corrects that fixture and passes mask 63: actual PrsExpression parsing,
all three OptPass012 passes, folded opcode/value and final token/counter/type
checks for `6*7;` and `1.25+2.5;`. The complete parser and optimizer bodies are
used on public system-heap controls. The fixture is retained as
tests/guest/i386-public-expression/ParserGraph.HC. An independent terminal audit
checks exact packaged inputs, exported records, fixture-only volume changes,
boot bytes and volume consistency. See docs/i386-global-alias.md. This is a
source-loaded graph diagnostic, not a delivered executable expression API.
Do not replace them with no-ops or a scalar-only constant evaluator. The nine
executable reference cases are a starting oracle; they do not qualify function
calls, globals, pointers, all operators, error/unwind behavior or C1–C5.

Formal evidence is retained under build/i386-public-expression-original-v2
and build/i386-public-expression-baseline-v1. The three publication attempts
are build/i386-public-expression-loader-v1,
build/i386-public-expression-loader-v2 and
build/i386-public-expression-loader-v3 and
build/i386-public-expression-loader-v4. Successful publication is retained as
build/i386-public-expression-loader-v5; optimizer/type controls use
build/i386-public-expression-loader-v6 and
build/i386-public-expression-loader-v7. The corrected graph result and audit are
build/i386-public-expression-loader-v9/result.json and
build/i386-public-expression-loader-v9/terminal-graph-audit.json.

The next integration work must complete the class/function-header services
around the real type parser and deliver the public-ownership backend adapter
through normal startup. The private backend
wrapper requires a private control owner and cannot accept these public controls.
Native expression compilation must also avoid the x86-64 host constant evaluator
used for cross-compilation. Calls, data relocations, full operator coverage and
error/unwind/cleanup behavior remain required; folded arithmetic alone is not
sufficient.


The source-loaded v10 probe adds an adapter from public allocations and controls
to the complete shared i386 backend. It supplies a temporary target function
frame, emits real target code into the public code heap, restores the caller
context and retires its IR/workspace. All nine executable records match the
actual original-v2 export byte for byte; 24 token cases and graph mask 63 also
pass. The terminal execution audit verifies exact packaged inputs, fixture-only
volume changes, boot bytes and volume consistency. Evidence:
build/i386-public-expression-loader-v10/result.json and terminal-execution-audit.json.
This remains a source-loaded prototype: normal startup still lacks the public
Lex/expression API. Class/type integration, calls, all operators, error paths,
cleanup and memory profiles require further work.

The expanded public runtime oracle is Runtime.HC in the same guest test directory,
run with tools/test-i386-public-expression-runtime.py. The actual original-v2
passes eleven cases: direct/nested calls, mutable I64/F64 reads and updates,
array indexing, a string argument, a raw cast and a wide shift. Sixteen repeated
calls recover both ordinary data and code heap usage. The normal native baseline
rejects missing Lex at line 13 after normal startup; an independent audit checks
current inputs, the exact fixture, fixture-only volume changes and boot bytes.
Neither result qualifies normal native runtime expression support.

The first expanded reference prototype assumed direct string-literal indexing
would consume the subscript; the original leaves the subscript as the next token.
Its decimal-initialized F64 update also differs by one low bit from the assumed
result. That failed oracle is preserved as runtime-original-v1. The final contract
uses ordinary array indexing and a string argument separately, and explicitly
initializes the F64 bit pattern before testing runtime arithmetic. It does not
qualify decimal initialization or direct string-literal indexing.


The reproducible source-loaded check is now:

    python3 tools/test-i386-public-expression-source.py IMAGE --out OUT

It passes in build/i386-public-expression-source-native-v1 on a 64 MiB native
486,-fpu guest. Nineteen published stages supply the complete lexer, shared
expression/type parser bodies, optimizer, canonical type/binary tables and the
shared i386 backend. BackendAdapter.HC is a test-only public-allocation adapter;
it retains temporary call descriptors, patches target call relocations after code
allocation, and uses actual kernel software-F64 helpers. TypeContract.HC covers
pointer variants, evaluated multidimensional bounds, an incomplete array, a raw
cast, F64 conversion and continued arithmetic. That initial probe source-loaded the exact
original LinkedLstDel body for dimension-list cleanup. Normal public copy/deletion
is now restored; see docs/i386-linked-list.md. Class/function-header joins and the stream service
remain explicit unresolved externs, with no replacement bodies.

All 24 token checks, graph mask 63, nine basic executable cases, six type checks
and eleven runtime cases pass. Basic/runtime exports match the actual original
records exactly, including both heap-recovery flags after sixteen repeated calls.
An independent terminal-source-audit.json verifies all 1025 current input pins,
exact packaged source/fixtures, fixture-only volume changes, boot bytes and volume
consistency. The ordinary native image still fails the separate missing-Lex
baseline. These source-loaded results do not qualify normal startup delivery,
class/function headers, retained external binding, debug records, error/unwind/
break behavior, complete operator coverage or the full compiler API.

Diagnostic failures remain preserved: loader-v11 uses invalid underscore-label
syntax for plain kernel helper exports; v12 adds an unnecessary extern declaration
that shadows the already defined LexExpressionI64; v13 passes basic execution but
its fixture lacks LinkedLstDel. The formal runner uses normal extern resolution,
keeps the existing expression definition and loads the real list-deletion body.


After restoring normal linked-list services, the current integration runner no
longer supplies LinkedLstDel. build/i386-linked-list-expression-native-v1 passes
all nineteen stages, 24 token checks, graph mask 63, nine basic executions, six
type checks and eleven runtime cases with exact original executable records.
Its terminal-integration-audit.json verifies all 1027 current pins, exact volume/
boot preservation and use of the delivered deletion binding without a test body.
This remains a source-loaded expression probe; normal Lex/compiler delivery and
full C1–C5 qualification are open.


The extended source runner now also checks retained expression code across control
release, an unresolved-call exception and later real function completion. The
original passes mask 15; the first source adapter failed mask 11 because it froze
the undefined target. Preserving the original indirect function slot and its
absolute relocation restores mask 15 while all earlier checks continue to pass.
See docs/i386-public-expression-lifetime.md and
build/i386-public-expression-lifetime-source-native-v1/terminal-lifetime-audit.json.
This covers that completion/lifetime path, while normal public compiler delivery
and the remaining class/header/stream/debug/error/operator work remain open.


The next shared declaration/initializer stage initially fails at missing
sys_var_init_flag (build/i386-public-declarations-source-v1). After restoring the
original shared controls and initialization policy, v2 publishes that complete
stage and passes all earlier token, graph, executable, type and lifetime checks.
The real class/function-header bodies and AOT store services remain to be
integrated; declaration publication alone is not full compiler delivery. See
docs/i386-variable-init.md.


The standard source runner now includes the complete declaration/initializer
stage by default. The formal twenty-stage run passes every existing token,
graph, basic/type/runtime and retained-call check, with exact original executable
records: build/i386-public-declarations-formal-native-v1. AOT byte-store callbacks
remain explicit unresolved externs and are not claimed as implemented.

Pass --classes to add the actual shared class/function-header bodies, real symbol
release wrappers, option accessors and diagnostics. The current formal mode
publishes the preceding twenty stages, then rejects HashSingleTableFind at
Part20.HC line 46 (build/i386-public-classes-formal-baseline-v1). The native
implementation exists in Kernel/I386/Hash.HC, but PublicHash.HH and the kernel
public export index do not publish it. This identifies the next integration
work, without replacing lookup semantics or class parsing. Independent terminal
stage audits verify both modes' inputs, packaged files, fixture-only volume
changes and boot bytes. Neither mode qualifies normal compiler delivery or C1–C5.

## Verification receipt for normal publication

`build/i386-normal-parser-cross-v4/final-verification-audit.json` checks all
1,833 source pins and 26 build-input pins, both disk hashes, module hashes and
layouts, bootstrap identity, every component receipt/input pin, unchanged
source-regression records, the actual injected failure signature, exact rasters
and both diagnostic recovery phases. It also verifies the preserved export
prefix, unchanged private compiler module, byte-identical expansion of the
three additional source extractions, and the unchanged 2/686 qualification
count. Its base revision is explicit so committing this checkpoint does not
change the source comparison target. The receipt lists the remaining limits.
