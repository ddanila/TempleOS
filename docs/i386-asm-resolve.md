# Deferred assembler resolution: original baseline

`tools/test-i386-asm-resolve.py` boots the pinned original OS and compiles the
complete original `Compiler/AsmResolve.HC` under private reference names. It also
loads the original non-public `AOTStoreCodeU8At` implementation needed by that
module. Both sources come from revision
`c26482bb6ad3f80106d28504ec5db3c6a360732c`; the runner records their combined hash,
restored OS hashes, fixture, runner, and harness input hashes.

The fixture executes allocated x86-64 expression thunks through `Call`. Each
increments an initialized counter before returning its constant. This checks that
construction defers execution and resolution executes each expression once.
There is an i386 thunk encoding in the fixture for subsequent native delivery;
this baseline does not qualify that encoding.

The 32 assertions cover:

- All eight signed-relative/immediate widths, truncated bytes and adjacent guards.
- A two-byte immediate crossing the 64 KiB AOT block boundary and the resulting
  length, while indexed stores leave the current assembly position unchanged.
- Undefined-expression addends and relocation type/site/packet ownership.
- Local precedence when both local and global reference lists are provided,
  constructor fields, LIFO insertion, local patching, list consumption, and a fresh
  local hash table chained to the global table.
- Two uses of an imported symbol: copied constructor names, immediate flags,
  metadata order, external alias naming, packet identity, and retained addends.
- A defined function's external call patch and exported name/type/address.

Original behavior is recorded explicitly: global resolution leaves its consumed
unresolved-list head and function external-usage head stale. It also retains the
constructor's duplicated import names. The fixture observes those pointer values
without dereferencing freed records, clears the heads, and frees the retained
names. A future shared/native implementation must specify and verify its repaired
ownership separately; an original pass does not prove native ownership.

Verified capture:

```
python3 tools/test-i386-asm-resolve.py --out build/i386-asm-resolve-original-v6
```

The result passes all 32 assertions and preserves raw relocation values in
`asm-values.bin`. Earlier failed fixture attempts remain under `build/`.

This is reference preparation toward public assembler and `CmpJoin` delivery.
Native bindings, global function-symbol fallback and goto records, branch-range
and diagnostic cases, exact heap accounting, allocation failures, partial-progress
exception unwind, assembler parsing, AOT file generation, and full compiler
self-hosting remain unqualified. No workflow or C1–C5 milestone count advances.

## Shared implementation and normal public delivery

`Compiler/AsmResolve.HC` now includes the complete `AsmResolveCore.HC` module.
Its four configurable implementation names let the normal x64 compiler and the
Adam-owned i386 service compile the same algorithms. The service publishes
`AsmResolve`, `AOTLocalsResolve`, `AOTGlblsResolve`, and `AsmUnresolvedAdd` through
normal typed facades declared by `Kernel/I386/PublicLoader.HH`. There is no private
compiler-controller cast or test-only replacement in that path.

The service's final function pointer is its complete-publication sentinel. The
existing wait/recheck and Adam hash-table restoration cover the expanded module.
All six JIT/AOT/resolver implementation pointers have system-task lifetime.
Console 255 appends four function exports to the existing 673-entry sequence;
the data masks and context-data index 671 stay unchanged. CompilerRuntime stays
at version 95. The strict build driver requires each resolver export to be a
function and rejects the previous Console module for missing `AsmResolve`.

Successful consumption now frees each unresolved record's owned `str`, clears
`glbl_unresolved`, and clears consumed function external-usage lists. Function
export generation explicitly obtains the function pointer from the symbol being
exported. Existing i386 import-name expansion and data-export tagging remain in
the shared module. These ownership changes do not add partial-progress exception
unwinding: a failure after earlier records were consumed remains open work.

The contract now has 38 assertions. Four one-past-range cases verify signed 8/16
rejection before writes. Undefined local/global symbols, a double-import
expression, and an unresolved export verify four further first-record errors;
these leave input ownership with the caller and do not execute their expression
thunks. Each case catches `Compiler`, and the combined error count is eight.
An independent eight-call `LexExcept` baseline measures diagnostic residue.

`asm-heap.bin` contains six signed words: first-use data/code growth, steady
resolver data/code growth after subtracting that independent diagnostic baseline,
and the measured diagnostic data/code costs. The first four must be zero. The
pinned original and shared x64 captures both measure diagnostic costs of 320/320
bytes; the runner never substitutes that value for the native measurement.
Original retained names and stale heads have explicit conditional expectations;
the shared/native case requires cleared heads and independently named i386
import records. Raw relocation values must match the original capture.

Verified current captures:

```
python3 tools/test-i386-asm-resolve.py --out build/i386-asm-resolve-original-v11
python3 tools/test-i386-asm-resolve.py --shared-x64 --reference build/i386-asm-resolve-original-v8 --out build/i386-asm-resolve-shared-x64-v2
python3 tools/test-i386-asm-resolve.py build/i386-asm-resolve-cross-v1/kernel.img --reference build/i386-asm-resolve-original-v11 --out build/i386-asm-resolve-native-v1
```

All pass 38/38 with unchanged pinned inputs. The native six-word heap record is
all zero; there is exactly one system publication. Normal arithmetic pixels and
mutated-volume validation pass, with only the fixture added to the packaged test
disk. The original cross-build image is not mutated. The shared x64 run compares
raw bytes against the earlier passing success baseline; the final audit also
compares them directly against the expanded original error baseline.

This delivery does not qualify the whole module or a complete workflow. Deferred
function-symbol fallback and goto-to-AOT integration, warning text, all valid
range endpoints, export-only function paths, data exports, allocation failures,
partial-progress unwind, first-use failure/retry/concurrency/cancellation,
assembler parsing, `CmpJoin`, AOT file generation and complete native generations
remain open. The compatibility matrix records component evidence without
advancing its 2/686 qualified-workflow count.

The same native contract also passes at 16 MiB using the preserved runner
`build/asm-resolve-native16-runner.py`, which changes only the repository root
location and Guest RAM setting. Evidence is
`build/i386-asm-resolve-native16-v1/result.json`: 38 assertions, identical raw
values, six zero heap words, one publication, arithmetic and volume validation,
and unchanged inputs. This includes actual first-use compilation of the normal
shipping resolver service at the compiler memory target.

Regression checkpoint: both original compiler/kernel rebuild generations pass.
`build/i386-asm-resolve-cross-v1` is the full 64 MiB native image, with 1,775 OS
source pins and 26 driver inputs verified unchanged. JIT/AOT fixup, carry,
class-metadata, and all 25 public-source compilation parts plus lexer, graph,
expression/type/runtime/lifetime/class/function/statement/ExeCmdLine/stream
execution regressions pass. The public-source suite still uses its compiler
adapter; it is regression evidence, not full normal compiler delivery.

The 16 MiB diagnostic TCG boot completes both program phases and their exact
code/file ownership markers. It and the 8 MiB normal TCG boot each match all
307,200 welcome/prompt pixels. The first 8 MiB attempt, run alongside the parallel
regressions, timed out at 360 seconds. It remains in
`build/i386-asm-resolve-welcome8-v1`. The unchanged-image KVM preflight passes;
the subsequent TCG run `build/i386-asm-resolve-welcome8-v2` passes in 235.62
seconds with a 900-second observation limit. This records functional startup
and exact pixels, not a newly qualified startup-performance budget.

`build/i386-asm-resolve-cross-v1/final-verification-audit.json` checks current
source/input hashes, original/shared/native records and raw values, both native
memory sizes, heap baselines, all regression receipts, both immutable image
hashes, export-prefix preservation, the previous-module rejection, bootstrap
receipts, diagnostic phase markers, and complete startup rasters.
