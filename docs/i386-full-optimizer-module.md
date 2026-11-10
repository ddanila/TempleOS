# Full shared optimizer module prototype

The original-User/on-demand-lexer prototype still exhausts public memory at
8 MiB while reading compiler-support source as DolDoc. The full shared optimizer
can now be cross-compiled as a separate native module, avoiding the need to
compile those bodies from source when a future loader is integrated. This is
an unintegrated prototype, not a replacement runtime or a passing memory result.

`docs/patches/i386-full-optimizer-module-prototype.patch` adds OptRuntime.HC only.
It includes the exact complete body/include sequence of PublicOptSupport.HC:
metadata initialization, parser stacks, target sizing, optimizer code, detach
and free handling, type/branch/size rewrites, diagnostics and passes 0/1/2.
No optimizer cases, warnings, errors or diagnostic character output are removed.
The native type headers and explicit imports replace the public source-loading
interface. Main initializes the complete opcode metadata and returns version,
structure size and the optimize callback. The struct is a provisional interface;
it does not yet describe all namespace publication obligations.

## Evidence

`build/on-demand-optimizer-v5` contains the successful classic-host cross build,
its source overlay, run.py, fixture and instruction audit. The bootstrap compiler
is the retained `build/rebuild-test` compiler; this does not qualify a fresh
current-source bootstrap or two native generations.

- Module: 138,522 bytes; code/data payload: 135,120 bytes.
- SHA256: `35710efdf869b440225162447853109a3f9eb89892c018da22b506af698ebe0a`.
- The cleaned v5 source produces the exact same module bytes as v4.
- Exact import contract: COCMiscNew, Free, MAlloc, LexExcept, LexWarn, Print,
  PrintErr, PutChars, Yield, throw, cmp, and eight software F64 operations.
- The complete 386 instruction audit passes with the retained module context.
  This proves emitted instruction compatibility, not runtime integration.
- The independent audit checks the original support include/body sequence is
  present verbatim, required helper/data exports exist, all 19 imports match,
  and its inputs remain unchanged.

Reproduce the retained experiment from the repository root with:

```sh
mkdir build/on-demand-optimizer-rerun
cp build/on-demand-optimizer-v5/{run.py,audit.py,candidate.patch} build/on-demand-optimizer-rerun/
cp -a build/on-demand-optimizer-v5/overlay build/on-demand-optimizer-rerun/
python3 build/on-demand-optimizer-rerun/run.py
python3 build/on-demand-optimizer-rerun/audit.py
```

Use a fresh output directory for a new experiment and preserve existing receipts.
The first two attempts were stopped after source inspection found an invalid
character-header path and a missing COCMiscNew import. The third timed out in a
boot-phase compiler panic: the captured screen identifies a PutChars signature
mismatch in character-output diagnostics. Adding the canonical explicit
`U0 PutChars(U64 chars)` import produces the successful v4/v5 module. These
failed attempts remain under their original build directories, with diagnoses;
they are not memory-limit failures or successful compilations.

## Integration obligations

Publishing only the optimize callback would break the subsequent parser.
PrsExpressionCore uses PrsPush, PrsPop and intermediate_code_table; PrsExp uses
OptFree; PrsDeclarationCore uses CmpTargetSize. Concrete line/hash evidence is
in `namespace-dependencies.json`; this is an illustrative dependency set, not
an exhaustive binding contract. The module exports these helpers and metadata,
but they are not yet published into the system compiler namespace.

A loader must preserve the complete required declarations and defines, canonical
type identity, helper visibility, shared mutable cmp state, owned image lifetime,
exception cleanup and serialized publication. It must validate the module and
returned interface before publishing anything. It must also demonstrate that
loading the 135 KiB payload fits the actual 8 MiB profile; a successful cross
build does not prove this. The existing source fallback and production startup
remain unchanged. Differential optimizer/diagnostic tests, original User and
recovery tests, malformed-module cases and native build/install manifests are
still required before production integration. C1–C5 remain open.
