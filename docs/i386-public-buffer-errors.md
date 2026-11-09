# Failed normal buffer ownership baseline

The C4 failure contract invokes the delivered normal `CmpBuf` API, without
replacing its parser or backend. Run it with a fresh output directory:

```sh
python3 tools/test-i386-public-buffer-errors.py IMAGE --out OUT
```

Five inputs fail after an incomplete first expression, completed expression,
completed function, initialized global, and imported call respectively. Each
must return NULL, report errors and no warnings, preserve its borrowed source
and the outer control queue, and restore both caller heap counters exactly.
Each case then compiles a fresh valid expression and releases its packet.
That per-case recovery check establishes packet creation, not execution.
After the worker task exits, backing usage/allocation counts and heap integrity
must return exactly to their pre-spawn values. A final console arithmetic
expression separately checks the rendered result 42. The runner checks recovery
and filesystem integrity before reporting a failed ownership comparison.

## Preserved failing evidence

`build/i386-buffer-errors-baseline-v1/result.json` tests the unchanged
`f03fd4bdb8a741a327c3256e0c19e63399e03cbb` image from
`build/i386-dollar-error-cross-v2/kernel.img`. Input hashes remained unchanged.
All five cases satisfy NULL/error/warning/source/queue checks and create a fresh
successful packet, but retain these bytes in each reported task heap counter:

| Partial compilation | Data delta | Code delta |
| --- | ---: | ---: |
| Incomplete first expression | 5888 | 5888 |
| Completed expression | 10528 | 10528 |
| Completed function | 11256 | 11256 |
| Initialized global | 10736 | 10736 |
| Imported call | 11392 | 11392 |

These are raw counter observations, not independently attributed allocation
sizes; the counters must not be added together as separate physical storage.
Every case reports two compiler errors. Task kill/validation succeeds but exact
backing restoration fails. V1 stops at the ownership mismatch before its final
arithmetic/filesystem checks; it does not establish those checks.

The strengthened runner repeats exactly the same 48 raw records in
`build/i386-buffer-errors-baseline-v2/result.json`. It additionally verifies
console arithmetic result 42, that only `/Probe/BufferErrors.HC` changed in the
filesystem, and that its allocation bitmap matches reachable extents. All
pinned inputs remain unchanged. The overall result remains FAIL because caller
heap and owner backing restoration fail; recovery does not erase those failures.

## Ownership work required

The shared `CmpJoinCore.HC` failure branch frees only the CAOT header and binary
blocks, leaving its temporary symbol tables and other partial packet ownership
unreleased. `CmpBufCore.HC` deletes its compiler control only on success.
Deleting the failed control alone cannot release the full graph: its destructor
releases lexer/control records, not code-control graphs or temporary tables.

A complete correction must preserve the existing parsing/join algorithm and
error counts, release owned import/export/relocation/heap-global and unresolved
records, restore nested contexts, and unwind code-control stacks. It must not
delete borrowed task tables installed during `#exe`, emit secondary undefined
label diagnostics while unwinding a primary error, or leave child packets linked
to a parent that has been released. Success paths, map output and escaped
literal lifetimes need regression coverage. OOM, arbitrary exceptions,
cancellation and concurrency need their own evidence; this five-case compiler
error fixture does not qualify them.

No production cleanup change or new bundled qualification is claimed by this
checkpoint. C1–C5 remain active and bundled qualification remains 2/686.
