# Volume paths and owned file reads

`Kernel/I386/RedSea.HC` supplies `I386RedSeaResolve`: a component-by-component
walker over one mounted volume. Absolute slash paths start at the volume root;
relative paths start at the caller's directory block. Repeated separators, dot,
parent entries and directory trailing separators are supported. Parent traversal
reads the target directory's self entry to recover its actual size. Files cannot
be traversed as directories. Components retain RedSea's 37-byte name limit.

The result is 1 for success, 0 for an absent entry and -1 for invalid input or
I/O failure. The output record changes only on success. This is volume lookup:
drive prefixes, backslashes, extension defaults and wildcard expansion are not
accepted pathname features. Callers exclusively own the volume/channel with
interrupts disabled, as with the underlying ATA reader.

`Kernel/I386/FileRead.HC` supplies `I386RedSeaReadAll` for a resolved entry and
`I386RedSeaFileRead` for a path. Successful reads return an owned heap allocation
containing every raw file byte and an additional NUL. Embedded NULs are preserved;
the optional size excludes the added terminator. Empty files return an allocation
of one byte. The caller frees successful results with `I386HeapFree`.

Both readers reject enabled interrupts. Allocation failure, invalid metadata and
incomplete reads return null, reclaim any temporary allocation and leave the
optional size unchanged. Metadata, heap and size output must remain valid and
exclusively owned throughout the call. Raw compressed files are not decompressed.
These functions are lower-level services, not the public TempleOS FileRead API.

KernelStorage uses the path reader for `/Kernel/I386/Kernel.HC`, retaining its
source hash, native lexer traversal and complete heap-reclamation checks. Native
include dispatch still needs public path/extension rules, decompression, file
input ownership and metadata, and integration with compiler controls.

The native `tools/test-i386.py --redsea` fixture checks absolute and relative
paths, repeated/dot/parent components, directory sizes, missing and invalid paths,
unchanged failure outputs, binary and empty file contents, optional size output,
161 exhausted heap arenas, immediate and partial I/O failures, and rejection with
interrupts enabled. The whole disk must remain unchanged. It uses a 128 KiB runner
and a separate 64 KiB heap; this is component evidence on QEMU/486, not strict 386
hardware qualification or a complete interactive-memory measurement.

## Extended-image recovery observer (2026-11-07)

The heap observer now validates the extended boot metadata and derives the
kernel payload base from it, rather than assuming the historical `0x11000`
address. Export bounds, runtime heap signature, arena bounds, exact used bytes
and allocation-count comparisons remain enforced. The resident-include layout
guard now matches the staged file-state record; its typed guest view checks
`busy` at offset 28 and `drive` at offset 32. Both file-read runners accept
`--welcome` for the current desktop startup.

`build/i386-file-observer-extended-v1/result.json` passes on the frozen private-read
candidate at 8 MiB TCG `486,-fpu`: all VGA checkpoints match, inputs remain
unchanged, and the observed heap retains exactly 5,419,624 used bytes and 17,197
allocations across the warmed arithmetic command. The observer's address is
1,058,136, derived from the 1,048,576-byte payload base and the bounded kernel
export. Current-image layout preflight and Python syntax checks pass.

This validates the observer, not the complete file-recovery workflow. The longer
public-read and resident-include recovery runs remain pending. The earlier
`i386-private-read-staging-public-v1` run was explicitly stopped because its
preloaded observer still assumed the obsolete address; its original oracle and
partial guest evidence are preserved. Runtime private-read allocation changes
are separate, unfinished work and are not qualified by this observer check.

## Private result ownership candidate (2026-11-07)

Native disk/cache reads requested through the private file service now stage
stored bytes and allocate the final result in the caller's explicit heap. They
no longer allocate an intermediate public result. Public `FileRead` retains its
existing task-owned result path, and resident entries retain their existing
owner. The original filesystem backend still reads through its public routine
and copies to the private caller, as before. Raw disk reads remain separate.

The private bridge commits size/attribute outputs only on success. Ordinary
private-heap exhaustion returns failure; an impossible cached byte count still
raises `OutMem`. Compressed private results use the existing checked expansion
service, with unchanged NUL termination and scratch-workspace cleanup.

The first stored-byte-only candidate (`i386-private-read-staging-cross-v1`)
passed the former staging failure but then exhausted the public allocator on
the same 7,423-byte file. The first direct-result candidate
(`i386-private-read-result-cross-v1`) exposed a failure-output regression in the
existing malformed-file diagnostic; the bridge's commit-on-success behavior
was restored before the subsequent candidates.

Current evidence for `i386-private-read-result-cross-v3`:

- Both original bootstrap generations pass, preserved under
  `build/rebuild-private-read-result-v3-verified`; the post-export audit confirms
  the guest sources still match their bootstrap hashes.
- Native cross-compilation, packaging and instruction audit pass. Compared with
  `i386-expand-workspace-cross-v1`, only `ConsoleRuntime.t32m` changes:
  2,052,967 to 2,054,394 bytes; all other common modules are byte-identical.
- Both compiler phases pass at 8 MiB, including worker file reads, the 128 layout
  assertions, public-header cleanup and disk-include recovery. The complete boot
  remains **failed**: `ProbeCodeLifetime` next requests a 13,575-byte child task/
  stack from the main heap, whose largest free block is 5,208 bytes. The recorded
  caller is `I386TaskCreateWithFilesFallback`; this is a separate later failure,
  not a complete 8 MiB diagnostic pass.
- The full 16 MiB TCG `486` diagnostic and exact welcome framebuffer pass in
  `build/i386-private-read-result-diag16-v3`. Both compiler phases and child
  code-heap lifetime phases complete; the final disk copy matches its source.

The 30-case focused contract passes at 8 MiB KVM `486,-fpu` in
`build/i386-private-read-contract-v4`, with unchanged input hashes, all typing
and result framebuffer checkpoints matched, and a unique guest completion
marker. It checks binary/NUL and original compressed bytes, empty results,
malformed archives, independent cached copies, ordinary private-heap exhaustion,
oversized-cache `OutMem`, unchanged failure outputs and exact restoration of the
explicit output heap. The contract uses the actual loaded function exports and
a separate heap; its fixture does not substitute implementations. The fresh
normal 8 MiB TCG welcome/clear/input check also passes in
`build/i386-private-read-result-welcome-v3`, with unchanged inputs and exact
pixels. Longer public-read/resident-include recovery runs on preceding frozen
candidates remain pending; they do not qualify this final candidate. Early attempts are retained:
`private-read-contract-v1` and `v3` rejected truncated keyboard commands, while
`v2` reached the compiler and rejected the helper's local initialized-array
declaration. Explicit byte assignments let this ownership fixture proceed; that
compiler rejection remains a separate C4 compatibility gap. The current runner
uses the existing framebuffer-acknowledged input harness, preserves its pixel
assertions, and also requires a unique guest completion marker. None of these
checks alone qualifies complete application compatibility or C1–C5.


## Synchronous terminal scrolling (2026-11-07)

The longer private-read-result public-read and resident-include runs are now
terminal failures, not pending checks. They completed the last submitted guest
command but failed the exact framebuffer assertion when output crossed the
60-row viewport. The public run stopped at command 20 (`ReadOwned`); the include
run stopped at command 22 (`CachedCode`). Source disk preservation passed. Those
completed command markers do not establish the offscreen result values.

A focused regression isolates this from file ownership: print 65 numbered lines,
then evaluate `6*7;`. The unchanged live WinMgr passes in
`build/i386-scroll-live-baseline-v1`. With WinMgr suspended,
`build/i386-scroll-suspended-baseline-v2` displays the command on the bottom row
but leaves its completed answer and prompt offscreen. The earlier suspended v1
used too short a timeout and is not evidence of the viewport bug.

Synchronous console presentation now temporarily forces the displayed document's
full refresh and runs three frames: finish layout, draw the resulting viewport,
and compose its cells. Previously two frames relied on periodic full refresh,
even though document recalculation adjusts the viewport after drawing and frame
composition precedes the document update. A render scope borrows the document
and its owner and restores the prior refresh flag during ordinary completion or
unwind. The scheduled WinMgr presentation path is unchanged.

Both bootstrap generations pass in `build/rebuild-console-scroll-v2-verified`.
Cross-compilation, packaging, instruction audit and the 1,725-source hash audit
pass in `build/i386-console-scroll-cross-v2`. Only ConsoleRuntime changes versus
the child-probe candidate, from 2,054,394 to 2,056,210 bytes. The first candidate
was rejected by the native parser at a ternary expression; the corrected version
uses an explicit branch. Full 8 MiB diagnostics still fail, now allocating
0x75510 bytes during probe loading, with a largest free block of 0x74ff0 bytes;
this candidate is not a full diagnostic pass.

`tools/test-i386-console-scroll.py` retains the existing all-pixel typing and
result assertions. At 8 MiB KVM `486,-fpu`, both
`build/i386-scroll-live-fixed-v1` and
`build/i386-scroll-suspended-fixed-v1` pass the 65-line tail, subsequent arithmetic,
and restoration of the initially clear full-refresh flag, with unchanged inputs.
`build/i386-scroll-forced-fixed-v1` also passes with the flag initially set,
including preservation of that flag and unchanged input hashes. Fresh longer
file-read/include workflows are running separately. These checks do not qualify the full desktop, application
suite, isolated startup timing, or C1–C5 completion.


The fresh full resident-include run on that frozen scrolling image
(`build/i386-scroll-resident-include-v1`) now passes the former offscreen
boundary, document/child/removal/default-extension workflows, intentional
OutMem rejection, borrow/lifetime recovery and successful include of 49. It
fails at command 44: CacheHeapsSame visibly returns 0 instead of 1. The source
image remains unchanged. This is a public-heap restoration failure, not another
offscreen-result timeout. The private-heap observer captured only its before
state, since its after hook follows the failed screen assertion. Exact-counter
diagnosis is running with the assertion unchanged; ownership leakage versus
retained document/compiler state is not yet determined.


The matching long public-file-read run (`build/i386-scroll-public-read-v1`)
finished with a different failure while typing command 44, ResidentHeaps. Earlier
ordinary, packed, owned, empty, missing and resident read/write checks passed
their screen assertions. The final recovery command was not submitted, so its
heap assertion has no result. Comparing the terminal framebuffer to its oracle
gives 38,507 differing pixels at the expected position, but only 64 after an
eight-pixel horizontal alignment. This points to a one-character horizontal
viewport shift; its cause and the remaining pixels are not yet resolved.
The source image is unchanged and terminal-failure-audit.json preserves the
checkpoint and comparison. No complete public-read pass is claimed.

## Public heap counter diagnosis (2026-11-07)

The resident-include driver now supports `--observe-public-heaps` with
`--failure-public-recovery`, emitting allocation-free hexadecimal counters at
the existing exact equality assertion. It also records submitted commands,
rejects commands exceeding the native 255-character input limit, and accepts
an explicit TCG/KVM accelerator (TCG remains the default). The observer does
not relax heap equality or classify unexpected queued jobs as harmless.

`build/i386-scroll-resident-include-heaps-v2` is terminal **fail**. Its original
oracle passes, and all 47 native commands fit the input limit (maximum 229).
The final guest log records quiescence true, caller used bytes 55,136 before
and 60,312 after, and root used bytes 797,760 both times. Thus the caller grew
by 5,176 bytes while the root did not. The host subsequently times out waiting
for the expected true result; this is not a missing observation of the assertion.
The source image and persisted fixture remain unchanged and the filesystem
allocation audit passes. `terminal-audit.json` records these values and hashes
the log, command list, result and frozen runner.

The previous heaps-v1 diagnostic failed before this assertion because its
logging function exceeded the input limit; its frozen runner and failure audit
remain preserved. Splitting the logging helpers made v2 executable.

This isolates the observed growth to the caller heap, but does not yet identify
its owner or establish a leak. The next control must distinguish retained
console/document/history allocations across separate commands from allocations
retained by failed or recovered include. The exact restoration gate remains
failing; no production fix or full resource qualification is claimed.
