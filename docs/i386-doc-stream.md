# Streaming document output compatibility

The next input dependency is the original `DocPrintPartial` API. Unlike complete
`DocPutS` parsing, it retains unfinished dollar commands across calls. This is
needed for standard output and the original document-backed input workflows.

## Reference and native tests

Run the pinned-original fixture:

```
python3 tools/test-i386-doc-stream-reference.py --out build/FRESH-reference
```

`build/i386-c1-doc-stream-reference-fixed/result.json` passes. The fixture checks
that `left$R` leaves visible text `left` and a two-byte pending dollar command;
`ED$cash$` completes the color command and begins a new dollar sequence; the
following `$right` completes an escaped dollar. The exported line is exactly
`leftcash$right` plus NUL. Separate exports prove plain-text markup remains
literal and insertion at column two of `abcd` produces `abXYcd`.

Run the corresponding public native API test:

```
python3 tools/test-i386-doc-stream.py IMAGE --out build/FRESH-native
```

Before implementation, on `build/i386-c4-getkey-final-cross/kernel.img`, the test fails at the first
`DocPrintPartial` call with an undefined-identifier compiler rejection.
`build/i386-c4-doc-stream-red/result.json` records the failure and unchanged
fixture/image/harness hashes. This is the expected missing binding, not a
passing native compatibility result. The later assertions remain unexecuted.

The first original run produced the correct exports but timed out because the
fixture omitted the harness's DONE marker. The corrected fixture above passes;
the earlier timeout is not evidence of an OS failure.

## Shared implementation

`Adam/DolDoc/DocPrintPartialCore.HC` contains the original streaming body.
Both the original DolDoc output module and the native console include it.
Console interface 77 adds the public `_DOC_PRINT_PARTIAL` binding; default
console string routing is not changed in this checkpoint.

The extracted implementation also passes the pinned-original fixture:

```
python3 tools/test-i386-doc-stream-reference.py --shared-stream --out build/FRESH-shared
```

Evidence: `build/i386-c4-doc-stream-shared-reference/result.json`. Bootstrap
rebuild and cross-build pass (`build/i386-c4-doc-stream-cross`). The new image
passes the 8 MiB startup regression with no BuildRuntime loads
(`build/i386-c4-doc-stream-startup/result.json`). After moving the public
declaration inside its include guard, a fresh bootstrap and final cross-build
also pass (`build/i386-c4-doc-stream-final-cross`). The final-image startup
passes in 44.82 seconds with no build-provider loads
(`build/i386-c4-doc-stream-final-startup/result.json`).

The native public API passes all 20 commands on the console-77 cross image
(`build/i386-c4-doc-stream-native-final/result.json`). The same 20 commands
also pass on the final image with the guarded declaration
(`build/i386-c4-doc-stream-delivered/result.json`). Text and pending-dollar
state match the original cases, including middle insertion. Two intermediate
native fixtures incorrectly expected silent top-level assignment expressions;
the framebuffer showed their numeric results. Void setup helpers correct those
expectations without changing OS behavior. The first timed out; the second was
stopped after the same mismatch was identified.

This retains the original implementation's normal-path behavior. Exception
cleanup is not yet hardened: a callback, allocation or parsing exception may
leave the formatted buffer or acquired document lock live. This remains an
explicit C4 gate before default-output integration.

## Remaining work

Qualify callback consumption, overstrike/data-entry
behavior, lock/resource cleanup and allocation failures. Then integrate default
console document output with faithful rendering and continue DocGetKey/GetStr.
These explicit-document cases do not qualify the complete API, standard-output
rendering, input editing or an entire inventory file.
