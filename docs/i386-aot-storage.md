# Shared AOT storage implementation

The next public compiler delivery dependency is AOT storage. The source-loaded
expression/statement pipeline still declares unresolved `AOTStoreCodeU8`,
`AOTStoreCodeU64`, `AOTStoreCodeU8At` and `PrsI386DataRange` callbacks. These
callbacks need real normal native bindings before that delivery gap can close.

`Compiler/AOTStoreCore.HC` now contains the existing four store implementations
(including `AOTStoreCodeU32`), included by `Compiler/AsmLib.HC`.
`Compiler/I386DataRangeCore.HC` contains the existing data-boundary recorder,
included by `Compiler/PrsLib.HC`. No function body changed. The source expansion
comparison against parent revision `52a9afc59d0e61b972a1c31812a1d34caf76292a`
is recorded in `build/aot-shared-core-source-audit-v1.json`.

That extraction checkpoint prepared sharing the actual implementation with normal
native console delivery. It added no exports and did not establish public AOT,
lexer, assembly, or compiler-module closure. The original block-allocation,
listing, cursor/high-water, variadic patching, and data-record ownership behavior
must be exercised through the eventual public bindings, including block edges.
The first binary block remains a caller precondition for sequential stores.

Extraction validation: two x86-64 bootstrap generations are recorded in
`build/rebuild-aot-shared-core-v1-verified/result.json`, with the console log in
`build/aot-shared-core-bootstrap-v1.log`. This is bootstrap validation, not a
native 386 public API contract or a C5 reproducibility result.

## Normal native bindings

Console version 251 appends five bindings without changing the existing 663
slots: `_AOT_STORE_CODE_U8`, `_AOT_STORE_CODE_U32`, `_AOT_STORE_CODE_U64`,
`_AOT_STORE_CODE_U8_AT` and `_PRS_I386_DATA_RANGE`. `PublicDocument.HH`
declares their original signatures. The console includes both shared bodies;
there is no public-to-private compiler-control cast or replacement allocator.
The expression source-loader now resolves these callbacks through those normal
bindings rather than introducing unresolved extern declarations.

`tools/test-i386-aot-storage.py` exercises a public `CmpCtrlNew` controller with
caller-owned AOT state and binary blocks. Twenty-four assertions cover sequential
widths, exact block ends, block crossings, sparse absolute variadic patches and
byte truncation, zero-filled holes, independent cursor/high-water behavior,
listing columns, data-record gates/order/64-bit fields, and exact used-byte heap
recovery after accounting for exported result buffers. The runner also checks
32 final binary bytes and the complete listing, exports raw captures, pins its
inputs, checks native arithmetic pixels, and validates the packaged filesystem.
It sets `DOCF_NO_CURSOR` on the listing capture document before `DocSave`.

The original reference source-loads the unchanged store implementations because
those functions are private in the original compiler, plus the port-specific
data-range recorder. It runs them with the original x64 compiler and layouts.
This distinction matters: the reference is not proof that original TempleOS
publishes these APIs. The native run uses the delivered bindings exclusively.

The initial original run stopped at the first private store symbol and was
interrupted deliberately to capture its debugger screen. Native v1 also exposed
an undeclared test constant. The v2 runs agreed on all cases except the listing
capture's default cursor marker. Original v3 passes all 24 guest assertions;
its runner incorrectly subtracted one from the already terminator-free `DocSave`
size and omitted the final listing space. These failed/cancelled captures are
preserved and are not passing evidence.

Full public lexer/compiler module delivery, assembly and AOT pipeline closure,
allocation-failure/cancellation coverage, and complete C1–C5 qualification remain
open. The component contract does not qualify a whole inventory workflow.

Validated native binding checkpoint:

- `build/i386-aot-storage-original-v4/result.json`: all 24 assertions, exact
  32 binary bytes and 34 listing bytes; unchanged inputs. The sibling
  `store-source-audit.json` proves byte identity with the pinned original stores.
- `build/i386-aot-storage-native-v4/result.json`: the same complete outputs,
  exact heap recovery, arithmetic pixels and packaged-volume validation.
- `build/i386-aot-storage-baseline-v2/result.json`: the previous Console 250
  image rejects the first missing store call. This expected failure uses the
  same final fixture and runner.
- `build/rebuild-test/result.json`: both bootstrap generations pass.
- `build/i386-aot-storage-cross-v1/result.json`: full image built, 1,765 source
  and 26 build-driver hashes independently checked; `export-audit.json` checks
  all 668 ordered export names and setters, including the five appended slots.
- `build/i386-aot-storage-carry-v1/result.json` and
  `build/i386-aot-storage-class-meta-v1/result.json`: both qualified workflow
  regressions pass with unchanged inputs.

Original/native v3 both passed all guest assertions but retained the one-byte
listing export-size mistake. V4 corrects that size without changing the store
implementation, expected listing, or other assertions.

`build/i386-aot-storage-source26-v1/result.json` passes all 26 published stages,
including the actual execution/stream contracts, with 1,041 pinned inputs. A
stale report label still described the AOT callbacks as unresolved; the later
`runner-metadata-audit.json` proves that only this report string changed after
the run. The captured runner remains in `runner-source.py`; all test commands,
generated source, expected records and checks are unchanged. The other 1,040
input hashes still match current inputs. This suite remains a source-loaded
compiler diagnostic, not normal full compiler-module delivery.

`build/i386-aot-storage-welcome8-v1/screen-oracle.json` passes the complete
307,200-pixel welcome screen at 8 MiB.

`build/i386-aot-storage-diagnostic16-v1/screen-oracle.json` passes the same
complete welcome raster at 16 MiB after both compiler phases, both code-heap
ownership transitions and both file-break cleanup cases.
`build/i386-aot-storage-cross-v1/terminal-audit.json` records the independently
checked build pins, unchanged normal image and complete diagnostic markers.
The diagnostic image hash also still matches the full-build manifest. Five
inventory guard tests and Python compilation checks pass. No additional workflow
is qualified.
