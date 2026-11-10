# Optimizer provider callback runtime experiment

The complete optimizer module now loads and executes through the normal public
OptPass012 facade in a disposable native candidate at 16 MiB. Its exact integer
and F64 traces match the pinned original system. This establishes the callback
path, not complete parser integration or the 8 MiB resource gate.

The patch `docs/patches/i386-optimizer-provider-loader-prototype.patch` applies
after the on-demand lexer prototype. It replaces the source optimizer loader
with a provisional module loader. The module source remains the complete shared
optimizer recorded in `docs/i386-full-optimizer-module.md`; its bytes are unchanged.
No production runtime source is switched to this prototype.

## Ownership and binding

The loader runs in Adam, dispatching other callers through Adam's serialized
job mechanism. It binds exactly the module's 19 imports to the existing system
services and the same mutable cmp object. The retained kernel already binds
all ten F64 helpers, including I386F64Mod; Console newly references that existing
binding. No kernel binding array, boot bytes or public service ABI changes.
The experimental Console import contract is the production set plus the existing
private I386CompactReadModule import and I386F64Mod, with no other additions.

The raw source buffer belongs to the kernel heap. The existing owned loader
validates, resolves, relocates and compacts it. Ownership transfers only after
success. Main initializes metadata and returns a versioned callback structure;
the loader checks status, version, structure size and callback bounds before
publishing the callback. The image remains pinned for system lifetime. Failed
loads free the still-owned source/image in its allocation domain; cleanup
failure stops the kernel. Failure cleanup has not yet received dedicated
malformed-module runtime qualification in this experiment.

The candidate under `build/optimizer-provider-load-v1` replaces only Console's
module and matching source, and adds OptRuntime's module and matching source
over the transitive guarded-header/lexer prototype. Independent packaging checks
preserve every other file, attributes, dates and boot bytes. It passes the full
386 instruction audit. Candidate SHA256:
`620bd25d63cf333692cd7a304068c382a042d78f3a8618c36821844a89c8616a`.
The retained bootstrap is used for the cross build; fresh bootstrap and native
generation qualification remain separate requirements.

## Differential and resource results

`tools/test-i386-public-optimizer.py` now accepts
`--optimizer-storage source|provider`, defaulting to source. It requires exactly
one selected load marker and zero markers from the other path. Native receipts
record storage and RAM settings. Provider mode requires a native disk. Original
reference behavior, fixtures and exact trace/heap expectations are unchanged.

- Provider at 16 MiB: PASS; 18 state checks are all one, exact 48-word trace
  matches the original, caller heap deltas are [0, 0], source/provider loads are
  [0, 1], and fresh arithmetic succeeds.
- Default source mode at 16 MiB: PASS with the same trace and heap requirements;
  source/provider loads are [1, 0].
- Original User startup at 8 MiB: FAIL before provider publication. The raw module
  read requests 138,523 bytes and throws OptFile. Kernel heap used/size are
  0x661B38/0x66FA00; largest free block is 0x4E48 (20,040 bytes). The module's
  135,120-byte payload also exceeds the remaining kernel capacity, so eliminating
  raw-file metadata alone is insufficient. Public-heap spare capacity has not
  been measured by this experiment.

`build/optimizer-provider-load-audit-v1/result.json` pins these receipts, actual
QEMU RAM commands and the expected failure log. Its audit verifies exact image
changes, unchanged module bytes, kernel F64 binding coverage, original trace
bytes, input hashes and load counts. A passing audit means these scoped results
are internally checked; the 8 MiB runtime result remains a failure.

## Required next work

The loader deliberately publishes only the optimizer callback. Later source
parser stages still require the optimizer's helper declarations, functions,
defines and opcode metadata in their namespace. Publishing those is mandatory;
the passing manual-expression fixture does not establish parser compatibility.
The existing namespace dependency evidence remains applicable. Runtime module
storage must also fit the actual 8 MiB memory layout, without increasing that
gate. Complete helper publication, negative-loader tests, broader optimizer
and parser differential coverage, original User/recovery regressions and native
build/install manifest integration remain open. C1–C5 are not complete.
