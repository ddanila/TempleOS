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

On `build/i386-c4-getkey-final-cross/kernel.img`, the test fails at the first
`DocPrintPartial` call with an undefined-identifier compiler rejection.
`build/i386-c4-doc-stream-red/result.json` records the failure and unchanged
fixture/image/harness hashes. This is the expected missing binding, not a
passing native compatibility result. The later assertions remain unexecuted.

The first original run produced the correct exports but timed out because the
fixture omitted the harness's DONE marker. The corrected fixture above passes;
the earlier timeout is not evidence of an OS failure.

## Remaining work

Share the original streaming implementation, expose the native public API and
pass the same assertions. Qualify callback consumption, overstrike/data-entry
behavior, lock/resource cleanup and allocation failures. Then integrate default
console document output with faithful rendering and continue DocGetKey/GetStr.
These explicit-document cases do not qualify the complete API, standard-output
rendering, input editing or an entire inventory file.
