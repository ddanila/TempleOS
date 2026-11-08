# Public compiler-control and lexer baseline

The original Psalmody source now reaches `CmpCtrlNew` in PsalmodyFile line
203. Native interface 225 rejects that call before application interaction.
The public control and lexer must preserve original ownership semantics;
exporting the private native constructor directly is insufficient.

`tests/guest/i386-public-lexer/Contract.HC` records twenty-four checks in an exact
192-byte table. It covers constructor flags and self-links, input-buffer
identity, current-task symbols, default filename and line, identifier/integer/
floating/string tokens, adjacent-string concatenation and returned ownership,
EOF, borrowed input lifetime, prompt allocation, at-sign handling, and heap
restoration after destruction. It also reads nested include files containing
Psalmody-style tempo and Play statements, concatenated notes and embedded-NUL
lyrics, and checks single-string pointer identity with `lex_next=FALSE`. The independent expected table contains twenty-four
64-bit ones. The runner preserves its source, fixture and input hashes.

Run the original oracle and native candidate into fresh directories:

```sh
python3 tools/test-i386-public-lexer.py --out build/public-lexer-original-new
python3 tools/test-i386-public-lexer.py build/i386-sprite-output-cross-v1/kernel.img --out build/public-lexer-native-new
```

## Preserved results

- `build/i386-public-lexer-original-v1/result.json`: pass, exact table, inputs
  unchanged during execution.
- `build/i386-public-lexer-native-v1/result.json`: fail at `CmpCtrlNew`, fixture
  line 6, before behavioral assertions; inputs unchanged during execution.

Both runs pinned the temporary archive-placement builder version. That helper
was subsequently restored after the unrelated experiment was rejected. Their
recorded input audits describe execution-time stability, not equality to the
current builder. The native image was the unchanged interface-225 Sprite image;
packaging preserved its boot area and original files.

## Implementation constraints and remaining scope

Original `CmpCtrlNew` accepts a public allocation and preserves its pointer.
`CmpCtrlDel` frees it unless `CCF_DONT_FREE_BUF` applies. Prompt buffers and
strings returned by `LexExtStr` use public `MSize`/`Free` conventions. Private
`I386CmpCtrlNew` instead validates arena-owned inputs, adds private control
state and uses arena cleanup. A direct export would violate this contract.

The fixture does not cover document input, general directives, error unwinding,
task death, or all `LexExtStr` modes. These require further oracle coverage and
implementation. The nested include fixture exercises the token pattern used by
Psalmody, but does not execute the full application or qualify its workflow.
This baseline closes no C1–C5 milestone.

## Nested include and song-token extension (2026-11-07)

`build/i386-public-lexer-original-v3/result.json` passes all 24 checks with
unchanged inputs. The added song and notes source files are pinned and included
in the reference ISO and native packaging. Nested includes return to EOF and
restore the initial public heap usage; embedded-NUL lyrics remain intact.

The preceding v2 result is preserved as a fixture error: check 18 expected seven
bytes for the seven-character note string, omitting its terminator. It was the
only failing check. V3 corrects the expected size to eight and reruns the full
original oracle; no production change was needed.

`build/i386-public-lexer-native-v2/result.json` still fails at CmpCtrlNew
before assertions, with unchanged inputs and the nested files packaged.


## Public character-stream oracle (2026-11-07)

`--characters` selects a separate sixteen-check public-input fixture while the
default mode retains the existing 24-token contract. The character fixture uses
CmpCtrlNew, LexGetChar, LexAttachDoc and CmpCtrlDel. It checks cursor-byte
skipping, newline/line-start accounting, one-character putback without advancing
the line, shifted-space normalization, repeated EOF, document include-stack
resumption, borrowed root-buffer identity/lifetime, ordinary document text,
tabs/newlines, and exact caller heap recovery.

`build/i386-public-characters-original-v3` passes the independent 128-byte table
of sixteen 64-bit ones. All recorded input hashes still match. The initial
fixture incorrectly called internal LexIncludeStr: original v1 ended without a
completion marker; v2 screenshots identify the compiler rejection at line 22.
That known-invalid v2 guest was explicitly stopped with its fixture, runner and
screenshot preserved. The corrected fixture constructs the include through
public LexAttachDoc instead. The runner now preserves waiting/failure screenshots
while retaining its overall completion deadline and exact byte oracle.

Native v1 rejects the missing LexGetChar at fixture line 11 before assertions.
The corrected-fixture rerun in
`build/i386-public-characters-native-v2` fails at the same missing call, with
unchanged inputs and before behavioral assertions. This is reference coverage, not an
implementation or compatibility pass. Prompt input, binary document entries,
error/unwind behavior and complete Psalmody workflows remain open.


## Public document attachment (2026-11-07)

Interface 227 exports original LexAttachDoc through
`Compiler/PublicLexDocumentCore.HC`. LexDocRead, the source-entry bitmap and the
attachment body are moved byte-for-byte from the original Lex source, which now
includes that same core. Native file-backed attachments use the public FileRead
dispatcher; this explicitly restores that alias after the original-media helper
includes. Public headers retain the original defaults and parameter order.

The independent `--attachment` fixture checks twelve results: supplied documents
and explicit entries/columns, clamping, copied filenames, parent-buffer resumption
state, new stack entries, reuse of a supplied record, borrowed root-document
lifetime, file-backed loading, empty-document state and exact heap recovery.
For reused records it releases the old filename first. For an empty supplied
document the original attachment stores a plain empty buffer and leaves document
cleanup to the caller; the fixture preserves and checks that behavior.

Original v1 had fixture errors: plain-text DocPrint returns no dollar-command
entry, and a reused lexer-file record's old filename was not released. Original
v2 selects an actual text entry and releases the old filename, then passes all
12 checks in `build/i386-public-attachment-original-v2`. Its execution inputs
were unchanged; the later interface-227 builder verifier update is preserved
alongside `pre-update-build-helper.py`. The native baseline rejects missing
LexAttachDoc before execution. The corrected fixture passes all twelve checks
and concluding arithmetic on interface 227 in
`build/i386-public-attachment-native-v1`, with unchanged input hashes.

Both bootstrap generations pass in `build/rebuild-public-attachment-v2-verified`.
The cross-build, packaging, instruction audit and source audit pass in
`build/i386-public-attachment-cross-v1`. ConsoleRuntime grows from 2,056,210 to
2,059,029 bytes; Kernel changes for the interface version, with unchanged size.
The other fourteen emitted modules are byte-identical. Source-block parity is
recorded in `build/i386-public-attachment-source-parity.json`. The full 16 MiB
diagnostic and exact welcome pass (`diagnostic16-audit.json`); the outer builder
interactive/rejection checks remain running. The fresh suspended 8 MiB KVM
scrolling regression passes all four exact typing/result pixel checkpoints and
restores the refresh flag in `build/i386-public-attachment-scroll-v1`, with
unchanged inputs. This qualifies the
attachment API, not LexGetChar, Lex/LexExtStr, prompt/error handling, complete
Psalmody, or C1–C5.


## Shared public character reader (2026-11-07)

The full original LexGetChar/LexDollar bodies are now shared with console 235.
On the fresh public-lex-cross-v3 image, `i386-public-characters-native-v4` passes
all sixteen original character/include/borrowed-buffer/heap checks. The public
control regression also passes all twelve checks. Separate prompt/refill and
echo/statistics contracts pass; see docs/i386-public-lex-char.md for source
identity, exact outputs and independent volume audits. Public Lex/LexExtStr,
full song loading and terminal execution remain open.


## Source-loaded token integration experiment (2026-11-07)

`build/i386-public-token-loader-v4` loads the complete current original `Lex`
and `LexExtStr` bodies and their shared helpers into a test task on the metadata
image (`i386-hash-source-cross-v1`). It passes all 24 original token, string,
nested-include and ownership checks, including embedded-NUL lyrics and exact
caller heap recovery, then passes the arithmetic glyph check. Its independent
terminal audit compares the exact fixture and 24-word export against original
v3, checks both function bodies byte-for-byte, and verifies unchanged boot bytes,
all original file tuples, exact added sources and volume allocation.

This is diagnostic evidence, not a production lexer. The prototype declares
`LexExcept`, `LexWarn`, `LexExpression` and `PrsStreamBlk` as unresolved externs;
the valid-input contract does not exercise those services. It also suppresses
`Kernel/CharBitmaps.HH` with its include guard and explicitly declares the two
existing kernel bitmap objects needed by the define reader, alongside the
already declared numeric bitmaps. This isolates header integration without
replacing any lexer body. The workaround is absent from production sources.

Earlier preserved experiments locate the failure: v1's combined library is
rejected during publication with exception zero and no compiler errors; v2
publishes declarations and file/member helpers, then rejects the token-helper
section; v3 publishes each helper through identifiers, then rejects the
`LexDefine.HC` section, which includes the shared bitmap header. V4 publishes
all thirteen stages with that header isolated and reaches the full contract.
The exact scripts, staged sources and results are retained under `build/`.

The next integration work is the public bitmap-header/export contract, followed
by real diagnostic, expression and executable-directive services and delivery
through shared startup. The prototype does not qualify those paths, complete
public compiler globals, physical terminal execution, or any C1–C5 milestone.

A follow-up diagnostic (`build/probe-public-token-no-bitmap-help.py`, evidence
`build/i386-public-token-loader-v5`) restored the shared bitmap declarations
through a staged copy of `Kernel/CharBitmaps.HH` with only its `#help_index`
directive removed. Normal startup succeeded, but publication of part zero
was rejected with exception zero, zero errors and zero warnings before any
token cases ran. The source image hash remained unchanged. Thus removing
that directive alone does not resolve header publication; this result does
not identify which declaration or binding causes the rejection.

The individual-declaration probe (`build/probe-public-token-bitmap-symbols.py`,
`build/i386-public-token-loader-v6`) successfully publishes the existing v4
prefix as part zero, then rejects part one, containing only
`public extern U32 char_bmp_alpha[16];`, with zero errors and warnings.
`KernelSymbols` does not export that name. This reproduces a specific missing
public bitmap binding independently of the combined header and help directive.
No token cases run in this negative probe.

The export control (`build/probe-public-token-bitmap-export-control.py`,
`build/i386-public-token-loader-v7`) publishes the identical prefix and then
`public extern U32 char_bmp_alpha_numeric[16];` successfully. The next stage,
`public extern U32 char_bmp_alpha[16];`, is rejected. Both declarations use the
same array shape and syntax; only the former has a kernel export. The source
image is unchanged. This supports adding the missing resident bitmap exports
before testing the complete shared header again.

The bitmap integration exports all seventeen original kernel bitmap arrays.
`PublicKernel.HH` includes the original guarded `Kernel/CharBitmaps.HH`; individual
word, whitespace and printable declarations have been removed. The document
runtime imports the canonical kernel printable array as `native_doc_printable`.
`_CHAR_BMP_PRINTABLE` remains a compatibility alias to that storage. Console
module version 237 records the changed import contract.

Resident binding now prefers an export matching the declaration's name before
falling back to address matching for differently named aliases. This prevents
an arbitrary same-address alias from triggering the publication collision check.
The rejected startup images remain in `build/i386-public-bitmaps-cross-v2` and
`build/i386-public-bitmaps-cross-v4`. Declaration probes v10–v13 further exposed
repeated extern declarations; the original shared header guard avoids these
redundant declarations in normal startup and token loading.

The final image is `build/i386-public-bitmaps-cross-v6`. Both bootstrap generations
pass with stable inputs, and the source audit checks all 1,749 production files
and all seventeen canonical bitmap exports. The public lexer echo/line-statistics
regression passes with mask 63 and current inputs in
`build/i386-public-bitmaps-lex-state-v3`. The 8 MiB welcome check compares all
307,200 pixels in `build/i386-public-bitmaps-welcome8-v4`.

`build/i386-public-token-loader-v14` publishes all thirteen stages using the real
shared bitmap header, verifies printable alias pointer identity, and passes all
24 original token cases. The independent terminal contract audit checks the
exact original fixture and output, unchanged source image, and exact complete
Lex/LexExtStr bodies. This remains a diagnostic source-loaded lexer: diagnostic,
expression and executable-directive services remain unresolved and normal
startup does not yet deliver the token API. Final-image 16 MiB diagnostics pass both program/ownership/cleanup phases and
the complete 307,200-pixel welcome frame in
`build/i386-public-bitmaps-diagnostic16-v4`, with an independent terminal audit. No C1–C5 milestone is qualified by these results.

## Normal token API delivery

Console 258 appends `_LEX` and `_LEX_EXT_STR` after the existing 680 public
exports, preserving indices and data masks. `Kernel/I386/PublicLexer.HH` supplies
the normal declarations. The facades load twelve ordered source stages in Adam on first
use, sharing the guarded compiler-service context with optimizer/backend/fixups.
Each completed stage advances lex_stage; a failed stage stops loading before API
publication. The final PublicLexSupport.HC initializes tables and publishes the
entries. Separate compilation releases temporary compiler state between stages.
The loader waits/rechecks Adam and restores its hash table on all exits. Failed
publication throws LexLoad. Invalid null control/include-stack input is rejected.

LexTokenCore.HC includes the complete previous LexIncludeStr-through-Lex body,
including all directives and shared string/number/character/punctuation/identifier/
define/conditional helpers. LexExtStrCore.HC contains the complete adjacent-string
ownership implementation. LexFilePushCore.HC extracts the existing include-stack
allocation helper. Include/string/identifier/define system helpers and LexDispatchCore.HC are shared
by both ordered stages and LexTokenCore.HC. Their concatenation reconstructs the
complete prior suffix apart from normalized separator blank lines at file ends. The original compiler includes these same bodies, with only
configurable implementation names added. No directive branch is replaced by a
restricted lexer. Source audits compare the complete extracted bodies.

Punctuation tables are allocated in the system task and initialized before
publication; partial allocations are released on exceptions. Existing complete
tables are reused; partial table state rejects publication. The cached string
entry is installed before the token entry, which marks successful loading.
First-use concurrency/cancellation and allocation-fault qualification remain open.

The normal API does not complete public compiler delivery: expression directives
retain the LexExpression dependency, and executable directives retain PrsStreamBlk.
Their complete normal parser/stream dependencies remain work in progress. The
source compiler regression still loads lexer/parser bodies diagnostically while
using normal optimizer/backend services. It validates the shared-body refactor,
rather than proving those unresolved normal directive paths work.

The full 24-check original and normal 16 MiB contracts pass with identical result
bytes, one normal lexer publication, arithmetic/volume validation and unchanged
inputs. The first broad header exhausted 8 MiB while compiling the unchanged
fixture include. Restricting PublicLexer.HH to PublicDocument.HH removes unrelated
IR/compiler/loader declarations and lets that fixture compile. No token test is
removed. The monolithic first-use library still exhausted memory in string-helper
compilation; ordered source stages advance the same 8 MiB test through that stage.

The current 8 MiB run remains a failure, preserved in
`build/i386-public-lex-native8-v3`. It rejects PublicLexNumber.HC with OutMem before
API publication: a 0xE14-byte parser payload request, heap usage 0x66FA28 of
0x671000 bytes, largest free payload 0x608, 0x4F6A live allocations. LexLoad then
reports the incomplete service. No 8 MiB lexer or C5 resource qualification is
claimed. The retained frontend's F64 helper-bound allocation and its surrounding
live IR/workspace are the next resource investigation; no grammar path is removed
to accommodate this limit. Normal parser/directive closure also remains open.

Current evidence is `build/i386-public-lex-cross-v3`, the original token contract
in original-v1 and normal token contract in native16-v3. The two service-order v4
runs load lexer/string, optimizer/backend and empty JIT/AOT fixups in opposite
orders, repeat calls and pass eight assertions, identical twelve-word traces and
zero caller data/code growth; every service publishes once. Earlier order v1
failures used a stack packet despite JIT's documented consuming ownership; v2/v3
correct that fixture before the final staged-loader rerun.

The full source compiler suite passes all 25 stages and lexer/graph/expression/
type/runtime/lifetime/class/function/statement/command/stream probes in
compiler-source-v2. This deliberately retains diagnostic lexer/parser loading,
with normal optimizer/backend calls. The normal backend's 48-check regression
also passes (backend-v2). Fresh original bootstrap generations, strict cross-build,
8 MiB TCG welcome and diagnostic 16 MiB TCG both ownership phases and complete
307200-pixel frames pass. The final audit checks current source/image/input pins,
ABI 96/258, retained export prefix/data masks, full helper-body reconstruction,
ordered stage files, passing records and the unchanged failing 8 MiB contract.
These component results do not qualify a complete workflow or C1-C5 milestone.

Final whitespace normalization removes only separator blank lines from four
extracted system-helper files. `build/i386-public-lex-cross-v4` has identical
native modules/flat kernel to v3 and only those four volume changes; preserved
prior files validate historical source pins. Its native16-v4 contract passes,
and native8-v4 reproduces the exact numeric-stage allocation failure above.
The final v4 audit covers these current-image receipts and the binary-identical
v3 regressions/rasters, with unchanged body tokens and normalized source pins.

The helper-frame resource checkpoint (`build/i386-helper-frame-cross-v5`, compiler
ABI 97, Console 258) removes the 3604-byte F64 helper descriptor from the compiler
arena for its emission/link lifetime. Its complete ten-helper metadata resides in
a checked stack frame; the integer-only path retains its small arena descriptor.
Borrowed AOT/hash/pass state is restored on exceptions before that frame retires.
The additional stack reserve is 4116 bytes above the existing 4096-byte downstream
reserve. Disassembly measures a 3808-byte local frame/argument/linkage delta;
this is not a bound on arbitrary recursive compiler or callback depth.

Private frontend IR storage now rounds the complete tree prefix to four bytes
(108 rather than 112). The following lifetime record contains only 32-bit fields;
its payload becomes 128 bytes and its physical heap span 144 rather than 152.
Public full-node allocations and all field offsets remain unchanged.

The unchanged 24-check 16 MiB token contract passes on this image. The 8 MiB
contract still fails in PublicLexNumber.HC, now after descriptor/proxy setup at
an emitter-buffer request of 0x1C4D bytes. Heap usage is 0x66D8C8 of 0x671000,
with largest free payload 0x5A8 and 0x4F7E live allocations. Aggregate free space
exceeds that request, but no contiguous block fits. Receipts are
`build/i386-helper-frame-lex16-v5` and `build/i386-helper-frame-lex8-v5`.
The next C5 resource investigation is emitter/IR lifetime and fragmentation;
normal parser/directive closure and 8 MiB lexer qualification remain open.

The checkpoint also passes both fresh original bootstrap generations, the strict
cross-build, all 25 diagnostic source-compiler publication stages through normal
optimizer/backend services, and the full 16 MiB diagnostic frame. Its new F64
helper fault probe validates failure/unwind/retry in both diagnostic phases.
`build/i386-helper-frame-cross-v5/final-audit.py` and
`final-verification-audit.json` validate current source/image/input/module pins,
compiled frame/node layouts, records and both passing and failing receipts.
Qualification remains 2/686; no complete workflow or milestone advances.

The compiler-98 scratch-output investigation rejects high-end private IR placement:
its unchanged 8 MiB contract fails earlier, on a 128-byte node during string-helper
loading (`build/i386-ir-high-lex8-v1`). Production retains first-fit IR allocation.
Segmented frontend output removes the single 7245-byte temporary-buffer requirement
without changing token bodies, grammar, the twelve source stages or the executable
allocation boundary after IR release. Windows adapt below 512 bytes to available
contiguous space and share one registered lifetime owner. Public emitter buffers
remain contiguous.

The compact-window v4 candidate reaches numeric-helper call-import emission but
cannot allocate its 68-byte rel32 import-fixup workspace: usage 0x670B20 of
0x671000, largest payload 0x30, 0x4F97 live allocations. The mapped call site and
44-byte record request are preserved in
`build/i386-segmented-cross-v4/allocation-frontier.json`. The record stores type 8
(IET_REL_I32); the initial literal-pool interpretation was incorrect (that type is
26). Compiler 98 separately reserves the required literal range before output
emission and tests its failure ownership. That change does not close the remaining
import-fixup frontier. Full 8 MiB lexer qualification still requires the unchanged
complete contract to pass.

Final build `build/i386-segmented-cross-v6` passes both fresh original bootstrap
generations, strict cross-build, the 24-check normal lexer16 contract, 48-check
normal backend, all 25 diagnostic source-compiler stages, exact 8 MiB welcome and
16 MiB diagnostic frames, both new metadata/F64 fault-recovery phases and the
expanded packaged inline-assembly contract. Its unchanged lexer8 receipt remains
failed at the same IC_CALL_IMPORT request/heap words above; API publication is
not reached. Current receipts are in matching segmented v6 directories and
`final-verification-audit.json` checks their pins/records. This does not complete
normal parser/directive closure, 8 MiB token loading or C1–C5 qualification.

The compiler-99 checkpoint (`build/i386-fixup-reserve-cross-v1`) reserves all
import/extern/address/poll fixups during measurement, before output windows
fragment the heap. The unchanged lexer16 contract still passes all 24 checks.
Lexer8 advances past the former import-fixup allocation, then fails in
PublicLexNumber.HC on a 52-byte IC_CALL_START context: heap 0x670B28/0x671000,
largest payload 0x30, 0x4F99 allocations. The mapped 26-byte CI386Call rounds to
32 plus its 20-byte lifetime. No lexer publication or 8 MiB/C5 pass is claimed.
Matching fixup-reserve v1 receipts and the final audit retain the full inputs,
passing regressions and this new resource failure. Call-context reuse remains
the next investigation; normal parser/directive closure remains open.

Compiler 100 reuses call contexts within and across backend passes, with complete
state reset and normal success/failure cleanup. On
`build/i386-call-reuse-cross-v1`, lexer16 still passes all 24 unchanged checks.
Lexer8 passes the former 52-byte call-context allocation point, then reports
EMITTER CHUNK SPACE REJECT in PublicLexNumber.HC. No usable output window remains;
this path reports no heap/count words. The test/input contract is unchanged and
normal API publication is not reached. Matching call-reuse v1 receipts and final
audits retain the passing compiler/backend/assembly/boot regressions and open
8 MiB resource failure. Normal parser/directive closure and C1-C5 stay open.
