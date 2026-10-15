# File reading through the complete original document loader

Console 105 routes the native DocRead file adapter through the complete shared
DocLoad implementation rather than NativeDocRecordLoadCore. Requested document
flags are applied before loading and are no longer cleared by a second reset.
This lets DocRead reopen menu/link commands, named colors, plain-dollar text,
CRLF, cursor markers and binary content produced by the full serializer.

A private preflight bounds the binary section after the first zero byte. Every
record must contain the complete CDocBin start/end header and declared payload
inside the file size. Zero-length records still advance by a header. The file
provider supplies an extra terminating byte for text; it is not included in the
file size. Missing files and truncated binary records retain the native NULL
result. Cleanup clears consumed buffer/document pointers before leaving the
adapter. Public layouts, export count (256), Memory 26 and private services are
unchanged.

## Contracts and reference setup

`tests/guest/i386-doc-read-reference/DocRead.HC` contains ten valid-file cases:
text, menu values, named color, link, CRLF, plain-dollar/tab flags, cursor marker,
independent binary record, empty file and zero-length binary record. Each requires exact text/structure,
flags and released locks, filename/attributes, preserved caller role/directory,
unchanged file bytes and exact caller heap recovery (mask 63).

The original reference boots from an ISO and cannot write its input volume.
Its runner adds independently constructed input files to an immutable overlay,
pins their hashes, and calls the same fixture with setup disabled and explicit
boot-drive paths. Native writes the same known bytes on a disposable writable
image and verifies FileRead size before measuring DocRead. FileWrite returns a
block count, so fixture setup checks success rather than equating it to bytes.
The actual input files must still match exact size and contents.

Three additional native cases require NULL, unchanged caller role and exact heap
recovery for a partial binary header, an oversized payload and the maximum U32 payload length (mask 7). Missing
file behavior is also checked. These native rejection semantics are not claimed
to match original DocRead, which returns an empty document on missing files.
The prior native menu case returns mask 60 and is rejected by a fail-fast wrapper.

## Boundaries

This integrates the file adapter with the full format loader; it is not a port
of the entire original DocRead wrapper. Default temporary filename, relative
pathname/context behavior, file links requiring a changed directory, constructor
failure, parser/callback exceptions, cancellation and committed Exit remain
separate gates. Binary preflight is structural bounds checking, not validation of
every document command or arbitrary entry graph. The retained editor's internal
restore path still uses its existing record loader.

Original undo timing/capture and full DocPutKey/chooser input remain open. See
PLAN.md for accepted run evidence; these contracts do not close C1–C5.

## Accepted evidence

`build/i386-c4-doc-read-qualified-reference` passes ten masks of 63 with pinned
input files and unchanged inputs. `build/i386-c2-doc-read-contract` passes all
valid-file cases, three masks of 7 for malformed binary records, missing-file
rejection and continuation in sixteen commands, with exact fixture readback and
unchanged inputs. The old native menu control returns mask 60.

The original two-generation bootstrap and `build/i386-c2-doc-read-cross` pass,
including the limited 386 audit (96 BIOS / 255 protected instructions); all 1487
source/build pins match. Serializer, loader, clipboard and retained keyboard undo
regressions pass. Normal 8 MiB startup passes nine checks in 57.60 seconds. These
results do not qualify the remaining wrapper semantics or C1–C5 completion.
