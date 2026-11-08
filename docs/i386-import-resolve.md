# Native import relocation and deferred resolution

Normal public compiler delivery still needs assembly/AOT joins and JIT fixups.
`CmpFixUpJITAsm` depends on `SysSymImportsResolve`; the source-loaded compiler
suite previously supplied it and `LoadOneImport` by copying `Kernel/KLoad.HC`.
That did not establish normal native delivery.

Console 252 now appends `_LOAD_ONE_IMPORT` and `_SYS_SYM_IMPORTS_RESOLVE`, keeping
all previous 668 names/setters unchanged (670 exports total). Both functions are
real boot-published bindings. Compiler/loader clients explicitly include
`Kernel/I386/PublicLoader.HH`, which declares their signatures and shared loader
flags. Ordinary `PublicHash.HH` remains unchanged. The kernel supplies its existing
`HashSingleTableFind` through one additional console module binding.

`Kernel/ImportResolveCore.HC` is included by both `KLoad.HC` and ConsoleRuntime.
`Kernel/LoadFlags.HH` shares the existing flags with `KernelA.HH` and loader
clients. The full compiler source-loader now includes the loader header and
calls the normal bindings; its copied loader implementation is removed.

## Relocation width and ownership

The original pointer arithmetic loses the high word of negative I64 relative
relocations when pointers become 32-bit. The port carries the patch address in
an I64 scalar, derives the relocation width once, adjusts relative target values,
and copies exactly that many low bytes from the I64 value. Both supported targets
are little-endian x86. The kind and width use U32 bookkeeping. Fictitious kinds
and kinds outside the original eight real relocation kinds retain their no-write
behavior. Group parsing, symbol selection, pending-import creation and
invalidation retain the original control flow and allocation ownership.

Pending imports become `HTT_INVALID` after resolution and remain allocated until
hash-table deletion, matching the original lifecycle. `SysSymImportsResolve` is
called after publishing the named export. Inputs are valid caller-owned streams
and patchable storage; malformed streams and direct resolution with a missing
export are outside the tested contract.

## Contract and evidence

`tools/test-i386-import-resolve.py` checks grouped cursor boundaries/terminators,
unresolved groups without writes, eight real relative/immediate kinds, fictitious
no-op kinds, 64-bit immediate values, function/global address fields, multiple
pending groups, invalidation/repeated resolution, inherited exports, task-table
restoration and exact used-byte heap recovery. It exports 24 assertions and four
raw backward displacements. Borrowed symbol storage is detached before deletion.
The runner preserves its fixture/source, pins inputs, checks native arithmetic
pixels and validates the packaged volume.

The original reference source-loads the immutable pinned original routines under
distinct names with the original x64 compiler/layouts. It does not load the new
core under test. The native run explicitly includes the delivered loader header
and calls the delivered bindings without source-loading their implementations.

- `build/i386-import-resolve-original-v5/result.json`: all 24 assertions and
  raw backward displacements pass, with unchanged inputs. Its
  `reference-core.HC` captures the pinned original routines.
- `build/i386-import-resolve-native-v6/result.json`: identical complete 192-byte
  assertion record and 32-byte displacement record, exact heap recovery,
  arithmetic/volume checks and unchanged inputs.
- `build/rebuild-test/result.json`: both bootstrap generations pass, with all
  1,768 source hashes independently checked before the EOF-only cleanup below.
- `build/i386-import-resolve-cross-v4/result.json`: full image build, with 1,768
  source and 26 build-driver pins checked. Its `export-audit.json` checks the
  complete ordered export table and unchanged preceding 668 slots.
- `build/i386-import-resolve-kvm8-v4/result.json`: fresh ordinary image completes
  startup and prompt construction at 8 MiB. This preflight is not a complete
  welcome-raster qualification.

The earlier `baseline-v1` and `baseline-v2` runs use earlier fixtures without the
new explicit header and reject the first absent helper call on Console 251.
They establish the missing-binding baseline, not the final backward-value oracle.

## Rejected candidates and boot declaration cost

Candidate 1's forward-only contract passed, but adding backward targets exposed
`00000000FFFFFFE0` instead of original `FFFFFFFFFFFFFFE0`. See the raw records in
`build/i386-import-resolve-original-v3/import-negative.bin` and
`build/i386-import-resolve-native-v3/import-negative.bin`. The 8 MiB TCG welcome
also failed: code allocation while compiling `UAsmCore.HC` exhausted the heap,
then prompt construction failed. Source-suite/16 MiB passes did not qualify it.
Its `candidate1-limitations.json` is preserved under `cross-v1`.

Candidate 2 reinterpreted a native pointer lvalue as U64 and consumed adjacent
storage, corrupting the high word; it also failed 8 MiB. Its
`candidate2-limitations.json` is under `cross-v2`. Candidate 3's I64 scalar/copy
implementation passes the full relocation contract (`native-v5`) and reduces the
store function's emitted span from 2,264 to 2,104 bytes, but still fails 8 MiB with
eager loader declarations in `PublicHash.HH`.

An isolation image blanks only the three new PublicHash lines at unchanged file
size; all compiled code and 670 bindings remain identical. It passes 8 MiB KVM
startup. `build/i386-import-resolve-header-isolation.json` records the changed-file
and volume audit; `build/i386-import-resolve-kvm8-header-isolation/result.json`
records startup. This isolates eager declaration metadata as the remaining cost.
The final explicit loader header retains both functions and their complete
contract while avoiding that metadata in unrelated boot clients.

The original extraction audit is preserved in
`build/i386-import-resolve-original-v1/source-audit.json`, including unchanged
flag expansion/non-UTF-8 bytes elsewhere in `KernelA.HH`. Intermediate bootstrap
captures remain under `build/rebuild-import-*-verified`; none substitutes for the
final checkpoint's bootstrap and native gates.

Full module loading, map output, assembler joins/fixups, error/OutMem/cancellation
paths, complete public lexer/compiler delivery and C1–C5 remain open. Component
coverage qualifies no additional whole inventory workflow; qualification remains
2 of 686.

## Final regression gates

`build/i386-import-resolve-source25-v2/result.json` passes all 25 published source
stages and their runtime/execution/stream contracts using the normal loader
bindings; all 1,044 pins still match. This remains source-loaded compiler
coverage, not delivery of the complete public compiler module.

Carry, ClassMeta and the previous public AOT storage contract pass on the final
image in `build/i386-import-resolve-carry-v2/result.json`,
`build/i386-import-resolve-class-meta-v2/result.json` and
`build/i386-import-resolve-aot-storage-v2/result.json`, with unchanged inputs.

The complete 307,200-pixel welcome raster passes at 8 MiB in
`build/i386-import-resolve-welcome8-v2/screen-oracle.json`. At 16 MiB, both compiler
phases, both code-heap ownership transitions, both file-break cleanup cases and
the same welcome raster pass; see
`build/i386-import-resolve-diagnostic16-v2/screen-oracle.json` and its debug log.
Five inventory guard tests and Python compilation checks pass.

`build/i386-import-resolve-cross-v4/terminal-audit.json` records independent checks
of every final report's pins before the EOF-only cleanup, build pins, unchanged normal/diagnostic
images and complete low-memory/diagnostic markers. These checks qualify the
component checkpoint, not the remaining C1–C5 release gates.

The verified implementation checkpoint is `23fc3c2a`. A later formatting-only
follow-up removes one extra LF after the core's final closing brace.
`build/i386-import-resolve-cross-v4/eof-whitespace-audit.json` checks the tested
core hash, saves `tested-import-core.HC`, proves that exact one-byte deletion,
and rechecks every other bootstrap/full-build/compiler-suite pin. No code tokens
or source positions before final EOF change; functional tests were not repeated
for this formatting-only cleanup.
