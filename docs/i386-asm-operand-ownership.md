# Assembly operand expression ownership

This C4 component change releases compiler-owned expression thunks and unresolved
symbol lists when assembly operand preparation raises an exception. It keeps the
shared original parser, instruction selection and encoding bodies. C1–C5 remain
open; this does not qualify the whole assembler or a bundled inventory entry.

## Ownership boundaries

`AsmLexExpression` now releases both the generated expression thunk and the
controller's pending symbol list on normal return and exception propagation.
This covers unresolved `ALIGN` and `ORG` values and evaluated `DUP` operands.

The instruction preparation guard releases unfinished pending expressions and
both parsed operands if parsing or instruction matching throws. When
`AsmUnresolvedAdd` publishes a reference, it detaches the corresponding owning
argument pointers. The encoder's selected instruction form retains its borrowed
copies, including the fields used to choose widths and emit displacement
warnings. Published references remain owned by the existing join cleanup.

Data-definition preparation has its own guard. A successfully evaluated count's
thunk is cleared immediately after release. Undefined DUP counts are rejected
before emission as before. Emission stays outside this guard because it may
transfer expression ownership to unresolved records.

The guards do not absorb exceptions or change error counting. Allocation failure,
cancellation, interrupted emission and arbitrary exception recovery through the
outer join remain unqualified.

## Reproducible before/after evidence

The ten-case `--operand-errors` mode uses ordinary public compiler entry points,
not a replacement parser. It covers incomplete immediate/address expressions,
an invalid instruction with unresolved arguments, unresolved ALIGN/ORG/DUP
values, a partial data expression, an undefined DUP count and a missing closing
address bracket. The final constant-expression error is a zero-retention control.

Native baseline: `build/i386-operand-baseline-v2/result.json`, using the unchanged
`a6c227b2c503c3924f5227d4ea4fbe2daa623531` image. Per-case data/code retained
bytes are `[24,176,24,88,88,88,24,88,88,0]`. Original x64 baseline:
`build/operand-original-before-v2/result.json`, with retained bytes
`[32,128,32,64,64,64,32,64,64,0]`. Both use the same final fixture as their
candidate runs. The original entry is public `Cmp`, which calls its internal
`CmpBuf`; the native entry is public `CmpBuf`.

Candidate original x64: `build/operand-original-after-v1/result.json`. All ten
heap deltas are zero, with unchanged error counts `[2,1,2,1,1,1,2,1,1,2]` and
byte-identical 81,920-byte captured diagnostics. The compiler and kernel rebuilt
themselves through two generations in `build/rebuild-test/result.json`.

The native fixture also checks source and queue preservation, fresh successful
compilation after each failure, task termination, exact backing heap recovery,
and owned diagnostic cleanup. The output cache is explicitly warmed and retained
by its kernel owner; it is neither subtracted from counters nor freed as a task
leak. See the ordinary buffer ownership evidence for the accounting contract.

Candidate native: `build/i386-operand-after-v1/result.json` on
`build/i386-operand-cross-v1/kernel.img`. All ten caller data/code deltas are
zero, and error counts match both the unchanged native baseline and original
x64. Source/queue/recovery and task/global backing assertions pass. Successful
assembly's twenty-four fields and expected short-displacement warning also pass
in `build/i386-operand-assembly-v1/result.json`.

## Regression and build audit

`build/i386-operand-cross-v1/final-verification-audit.json` checks 1,850 source
and 26 helper hashes, sixteen delivered modules, both original bootstrap
generations, the preserved baseline inputs, raw before/after records and original
diagnostics. The earlier bootstrap is preserved at
`build/rebuild-test-before-operands`; baseline receipt paths are resolved there
when checking its unchanged hashes.

All candidate receipts use the same delivered native image: ordinary ten-case
errors (`i386-operand-normal-v1`), nested ten-case errors and three caller boundary
checks (`i386-operand-nested-v1`), fourteen successful buffers
(`i386-operand-success-v1`), successful assembly (`i386-operand-assembly-v1`),
46 earlier compiler-error cases (`i386-operand-errors-v1`) and ten DolDoc cases
(`i386-operand-doc-v1`). Six saved packets execute independently through ELF32
in `i386-operand-elf-v1`. The shared resolver's 38 assertions also pass on
original x64 and native in `operand-resolve-original-v1` and
`operand-resolve-native-v1`; partial-progress/OOM resolution remains outside
that contract. All paths here are under `build/`.

ABI stays Compiler104/Console264/Memory41, with 691 exports and 22 mask words.
The inventory guards pass and qualification stays 2/686. Desktop/app workflows,
resource/performance profiles and full native C5 release generations remain open.
