# Fixed graphics buffers and parser headroom

The DocScanLine checkpoint exposed an 8 MiB regression: normal boot completed,
but the first retained function failed a 537-byte parser allocation. The failed
image and immediate-rejection rerun remain under
`build/i386-c1-doc-scan-startup{,-rejection}`.

## Diagnosis

A disposable no-FPU guest was stopped through QMP after reproducing the rejection
and its 8 MiB physical RAM was captured without changing guest code. The memory
snapshot, capture/inspection scripts and hashes are in
`build/i386-c1-arena-pressure-snapshot`. Inspection found no fully free cached
page blocks in the root public heap. Its two live 640x480 device-context pixel
arrays each requested 307,200 bytes but occupied 1,026 pages (525,312 bytes),
with a reported payload capacity of 525,276 bytes. They were identified through
the loaded console symbols and each device context's body pointer.

This is page-bucket reserve overhead, not a reason to reduce display dimensions,
remove a graphics context, or raise the existing minimal RAM profile.

## Allocation contract

The internal memory core accepts an opt-in `exact_pages` argument. Existing
callers default to the original normal buckets and pressure fallback. Explicit
exact requests skip bucket growth and split larger returned buckets, retaining
the unused prefix as a reusable free extent. Page ownership, signatures,
accounting, alignment and interrupt restoration follow the existing paths.

The retained memory service exposes private `I386CAllocExact` through memory
interface 23. Console interface 70 requires that binding. `DCNew` has a shared
pixel-body allocation hook: the original target defaults to CAlloc; the native
target uses the exact service. Header/matrix allocation, pixel byte count,
zeroing, device-context ownership, public MAlloc/CAlloc defaults and normal
Free/DCDel remain unchanged. No private pointer or implementation detail is
added to an application-facing flow.

Native `MSize`/`MSize2` and `DCSize` can now report smaller reserved pixel-body
capacity. They continue to describe the actual allocation; logical width,
height and every pixel byte are unchanged. This is an intentional allocation
policy difference to record in C4, not a claim of identical x64 memory layout
or padding capacity.

## Test-first evidence

The protected-mode cache test first failed with return 163 when the accepted
exact flag still used normal allocation. Two 280-page requests could not meet
the 600-page budget. After implementing that option, an expanded test failed
with return 170 because a reused larger bucket was consumed whole. The final
path splits that bucket. Both failed artifacts, compiler ISOs and source
fixtures are preserved in `build/i386-c1-exact-pages-{red,reuse-red}` with
`baseline.json` records. An earlier unsupported-signature run timed out during
compilation; it is not the behavioral baseline.

The tests also require a normal 280-page request to keep its 514-page bucket,
retain simultaneous payloads, restore IF and return all page ownership. The
backing suite adds two concurrent 140,000-byte exact payloads in a 320 KiB arena,
with full-byte preservation, capacity limits, ordinary frees and final backing
reclamation.

`tools/test-i386-fixed-graphics.py` checks the actual delivered image through
public APIs: both 640x480 contexts, root heap ownership, bounded pixel capacity,
the original twenty-case graphics-context workflow and subsequent arithmetic.
The existing startup gate remains the authority for the retained 8 MiB workload;
passing a larger-memory capacity check alone cannot restore that gate.

## Qualification checkpoint

The final source bootstraps/rebuilds twice and cross-builds with the 386 loader
audit. The first cross-build rejected an unsupported `#undef` in the allocation
hook; it is retained in `build/i386-c1-exact-buffer-cross`, and the corrected
build is `build/i386-c1-exact-buffer-cross-v2`.

These allocator suites pass:

- `build/i386-heap-cache-test/result.json` (exact growth/reuse and normal buckets).
- `build/i386-heap-cache-source-test/result.json` (portable heap validator).
- `build/i386-heap-public-test/result.json` (public allocation, backing and both
  concurrent exact payloads).
- `build/i386-backing-accounting-test/result.json` (live/cache ownership).

The 8 MiB startup gate now passes all nine commands and exact VGA checkpoints
in 41.9456 seconds, with zero build-provider loads:
`build/i386-c1-exact-buffer-checks/startup-8m/result.json`. The earlier failed
source candidate remains preserved. Complete desktop/application parity and
C5 native-generation release qualification are not established by this gate.

The delivered-image capacity baseline also fails as intended at 64 MiB:
`build/i386-c1-fixed-graphics-capacity-red/result.json` rejects the oversized
body capacity on command 03 after dimensions and ownership pass. Input hashes
are unchanged. Ownership is checked against each context's recorded memory
task, since boot reservations belong to the immortal root rather than the
interactive child task.

The corrected image also passes all nine fixed-graphics commands at 8 MiB,
including all 307,200 frame bytes initially zero, recorded memory-task ownership,
bounded body capacity and the twenty-case context workflow. Inputs are unchanged:
`build/i386-c1-exact-buffer-checks/fixed-graphics-8m/result.json`.
All seventeen DocScanLine commands pass at 64 MiB on the same candidate:
`build/i386-c1-exact-buffer-checks/doc-scan-64m/result.json`.

The complete serial acceptance queue passes:
`build/i386-c1-exact-buffer-checks/result.json`. Its final graphics stage passes
eleven commands, including allocation-failure recovery, frame-state exception
recovery, all four independently pixel-checked graphics frames and the context
workflow at 64 MiB on `486,-fpu`. All framebuffer checkpoints match; source
image preservation matches the cross-build manifest. This closes the immediate
8 MiB regression without qualifying full desktop/application compatibility or
C5 native generations.
