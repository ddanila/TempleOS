# Partial DolDoc error-entry ownership

Malformed commands can allocate a tag, auxiliary text, a define, HTML text and
left/right macros before reaching a parse error. The shared grammar previously
changed that entry to `DOCT_ERROR` and cleared `de_flags`. `DocEntryDel` relies on
those flags to release the payload, so ordinary deletion could no longer find
its owned strings. The normal native baseline retains 16 bytes for single-tag
failures and 112 bytes for the tested multi-field failures.

Both error conversions now call `PrsDollarErrorEntryCore`. It clears the parser's
ownership slot before releasing the partial entry through the existing complete
`DocEntryDel`, then creates a zeroed error record. Releasing the old entry before
allocating its replacement avoids keeping two entry records live. Clearing the
slot first prevents an allocation failure on the explicit-error path from
leaving a freed entry for the enclosing catch to release again. This does not
qualify allocation-failure handling throughout the parser.

A `BI` number sets the bin flag before validation or binding acquires a bin
reference. The helper clears that flag when `bin_data` is null, so the standard
deleter does not report an attempted release of an unacquired bin. Existing
non-null references retain their ordinary deletion path. The grammar body is
otherwise unchanged, including its `DOCT_ERROR` return contract and exception
absorption. The ordinary entry destructor is unchanged.

## Checks

```sh
python3 tools/test-i386-doc-public-boundary.py IMAGE --out NATIVE_OUT
python3 tools/test-doc-dollar-error-component.py --out X64_OUT
python3 tools/test-doc-dollar-error-component.py --baseline-revision 4d74cb9c --out BEFORE_OUT
```

`build/i386-dollar-error-baseline-v2` runs the expanded caller fixture against the
unchanged 4d74cb9c normal image. Valid entries, queue restoration and task
reclamation pass, but the single-tag and unbound-bin error paths retain 16 bytes
on each reported heap, and the multi-field error paths retain 112. Those are raw
caller counters; no estimated allocation sizes are subtracted.

`build/i386-dollar-error-contract-v2` passes all ten cases through the delivered
normal `PrsDollarCmd`: two valid entries, caught and explicit parse errors,
multi-field partial payloads, an unknown command before entry creation, and
unbound bin declarations. Every case preserves the public compiler queue and
flags and returns both caller counters to zero after ordinary deletion. The
owner task also terminates with exact backing usage/allocation recovery, and
fresh arithmetic pixels pass afterward. The only disk addition is the fixture.

`build/i386-dollar-error-x64-before-v3` and `...-x64-after-v3` use the same fixture
and immutable original x64 scaffolding, selecting the complete old/current shared
grammar body. They retain real Lex/LexExtStr and scalar evaluation, with controlled
expression failures to exercise the catch path. The old body leaves tags and
positive raw heap totals; all eight current-body rows are `[1,1,1,0,0]`. This is
cross-architecture ownership evidence for the shared body, not a replacement for
the native normal-API contract or full original document qualification.

The final audit is
`build/i386-dollar-error-cross-v2/final-verification-audit.json`. It checks 1,847
source and 26 helper hashes, all sixteen modules, two original bootstrap
generations, exact grammar/destructor scope and the before/after fixtures. The
final image also passes the unchanged fourteen-case buffer contract, all 46
compiler error rows and ten repeated printed-field cycles at 64 MiB KVM. This
checkpoint changes no exported ABI and makes no new startup-performance or
complete native-release claim.

OOM, cancellation during parsing, failures inside bin binding, missing-bin
validation, document interchange and complete desktop/application qualification
remain separate. C1-C5 remain active and bundled qualification remains 2/686.
