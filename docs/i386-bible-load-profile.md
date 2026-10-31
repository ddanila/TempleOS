# Bible document loading profile

The full Bible editor-link test timed out during its first lookup at the
20-minute command limit. To locate the expensive stage,
`tools/test-i386-bible-load-profile.py IMAGE --out OUT` loads four prefixes of
`Misc/Bible.TXT` into disposable guest files. Each case reads its excerpt,
inserts it into a plain-text document, lays it out, finds Genesis 1:1, and
frees it. The host records debug-marker arrival times; these are elapsed QEMU
measurements, not CPU samples or a physical-machine benchmark.

The run on the Console 176 native image passed all four searches with unchanged
inputs (`build/i386-bible-load-profile-v2`). Times are approximate seconds:

| Lines | Read | Insert | Layout and search | Cleanup | Total |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 400 | 2.3 | 1.8 | 9.0 | 7.3 | 20.4 |
| 800 | 4.9 | 5.2 | 0.1 | 21.5 | 31.8 |
| 1,200 | 7.1 | 10.7 | 0.2 | 43.8 | 61.8 |
| 1,600 | 10.7 | 18.7 | 0.2 | 72.6 | 102.2 |

The first search also includes loading the editor module, so the first search
is not directly comparable with the later cases. Cleanup grows rapidly and is
the largest measured stage at 1,600 lines; insertion also grows faster than the
file read. This does not by itself identify a particular function or establish
full-file completion. Public `MemoryFree` invokes backing-pool reclamation after
every non-null free, including small frees that remain in the heap cache; the
cost of that validation and its corruption-detection guarantees need to be
measured before changing it.

The first profiling attempt completed two cases but lost the next keyboard
command (`build/i386-bible-load-profile-v1`); the accepted run sends one
combined command and records partial markers even on failure. The test uses
bounded excerpts and is not a substitute for the full Bible test, installation,
application compatibility or C1–C5 qualification.

A separate QMP sampler paused a 1,200-line run during cleanup
(`tools/profile-i386-bible-cleanup.py IMAGE --out OUT`,
`build/i386-bible-cleanup-pc-v1`). Of 213 samples, 208 landed in
`I386HeapScanSelect` with callers through `I386HeapSize`,
`I386MemBackingValid`, `I386MemBackingTrim` and `MemoryReclaim`; four more
landed in the same scan through `I386HeapValid`. These are statistical samples,
not call counts or elapsed-time measurements. They support targeting repeated
whole-arena validation while retaining the full validation and ownership checks.

## Validated backing lookup

Memory runtime 34 validates the entire bootstrap heap once while interrupts are
masked, then walks that already-validated chain to find each backing region's
exact allocated block and requested size. It does not cache validation or skip
reclamation. An inline 386 span walk avoids the cost of generated wide-code
loops; the portable source path uses the same bounded offsets. The public heap
contract compares the result with the previous full-scan implementation on
valid state, changed ownership counts and sizes, reserved metadata corruption,
and a forged pointer inside a different live allocation. Native and portable
heap tests pass (`build/i386-backing-validator-test-v4.log`,
`build/i386-backing-validator-source-test-v3.log`). Both bootstrap generations
and the native cross-build/386 audit pass
(`build/i386-backing-validator-rebuild-v3.log`,
`build/i386-backing-validator-cross-v3`). The 8 MiB drive-fields smoke
check also passes (`build/i386-backing-validator-smoke-8m-v2`).

The same scaled workload passes on the candidate with unchanged inputs
(`build/i386-bible-load-profile-optimized-v3`): at 1,600 lines, read took about
6.8 seconds, insertion 5.5 seconds, cleanup 19.5 seconds, and total 32.0 seconds.
The earlier image took 10.7, 18.7, 72.6 and 102.2 seconds respectively. These
are approximate host-observed QEMU timings; another guest was active during the
candidate run and the command wrapper was shortened, although the measured
`BibleProfile` stages and text samples are unchanged. The improvement does not
qualify the complete Bible or eliminate its scaling cost. An earlier generated
walk showed severe slowdown and keyboard input resets, so it was superseded;
its partial run was stopped after the inline candidate superseded it
(`build/i386-bible-load-profile-optimized-v2`, inputs unchanged); its failed
concurrent command attempt is `build/i386-bible-load-profile-optimized-v1`.

The candidate passes the isolated initial memory probe in diagnostic boot. The
full 8 MiB diagnostic later exhausts the bootstrap heap on both candidate and
prior images (`build/i386-backing-validator-diagnostics-v1`,
`build/i386-backing-validator-diagnostics-control-v2`). At 16 MiB both reach
the later public-header probe and fail on the same `PublicTask.HH` invalid-lvalue
error (`build/i386-backing-validator-diagnostics-16m-v1`,
`build/i386-backing-validator-diagnostics-control-16m-v1`). The control used
the default 486 CPU setting; these matching failures do not establish complete
diagnostic qualification.

The normal 8 MiB startup gate completed all nine behavior checks but exceeded
its 60-second target: 77.399 seconds for the candidate and 84.891 seconds for
the prior image in an isolated control checkout
(`build/i386-backing-validator-startup-v1`,
`build/i386-backing-validator-startup-control-v2`). Both gates therefore
remain failed on timing; these two runs do not prove the startup target. The
runner was updated to expect the current welcome screen, and its 60-second
threshold was retained.

A repeat cleanup sampler on the optimized image passed with unchanged inputs
(`build/i386-bible-cleanup-pc-optimized-v1`). Of 58 samples, 46 landed in
`I386MemBackingValidatedSize`, seven in its caller and five in the complete
heap validator. This identifies the remaining per-region walk as a likely
cleanup cost; the samples do not establish call counts or full-file latency.

## Bounded multi-region walk

A Memory 35 candidate handles up to 64 owned backing regions by collecting
heap-range-checked link addresses into private scratch storage, sorting them,
and checking exact allocated-block membership with one forward walk of the
already validated heap. The entire operation masks interrupts; native memory
services assume one CPU and no NMI callers. The ownership list is not mutated,
and the previous per-region lookup remains the fallback above 64 regions. The
private scratch avoids the initial candidate's 336-byte validator stack frame;
the final native function reserves 80 bytes. This is a frame measurement, not
proof for every task stack or reentrant execution.

The native and portable heap tests compare the earlier validator with the new
one for valid and corrupted records, a cyclic list, a forged interior pointer,
and out-of-arena pointers. They exercise exactly 64 regions with both list
orders and 70 regions through the fallback
(`build/i386-backing-multilookup-final-test-v1.log`,
`build/i386-backing-multilookup-final-source-test-v1.log`). The native task-heap
ownership and lifecycle suite also passes
(`build/i386-backing-multilookup-task-heaps-v1.log`). The final-version
isolated checkout passed both bootstrap generations and its 386 cross-build
(`build/i386-backing-multilookup-isolated-rebuild-v1.log`,
`build/i386-backing-multilookup-candidate-tree/build/final-cross-v2`). The 8 MiB
drive-fields smoke also passes (`build/i386-backing-multilookup-final-smoke-v1`).

The final candidate's 1,600-line profile passed with unchanged inputs
(`build/i386-bible-load-profile-multilookup-final-v1`): read took approximately
7.4 seconds, insertion 2.1 seconds, cleanup 5.8 seconds, and total 15.4 seconds.
The previous validated single-region walk measured 6.8, 5.5, 19.5 and 32.0
seconds respectively. Both measurements overlapped another guest; these are
approximate QEMU elapsed times, not a hardware benchmark. The fast path's bound
means this does not establish performance for the complete Bible or for lists
above 64 regions. The full-file test on the preceding image also timed out at its 20-minute
command limit, with unchanged inputs
(`build/i386-doc-bible-link-full-optimized-v1`). The final candidate full-content
image passed its cross-build and 386 audit
(`build/i386-backing-multilookup-candidate-tree/build/full-cross-v1`), and its
full Bible-link test also timed out at the 20-minute command limit with
unchanged inputs (`build/i386-doc-bible-link-full-multilookup-v1`).

The final Memory 35 image passes its initial isolated memory probe in the 16 MiB
diagnostic boot, then hits the same prior-image `PublicTask.HH` header failure
(`build/i386-backing-multilookup-final-diagnostics-v1`); this remains a failed
full diagnostic, not a diagnostic qualification.

## Unbounded batched region validation

Memory 36 removes the 64-region performance cliff. It follows the ownership
list in batches of at most 64 range-checked addresses, sorts each batch in the
same private scratch storage, and walks the already validated heap once per
batch. All regions still receive exact allocated-block and metadata checks under
interrupt exclusion; the list is not modified and there is no limit on its
length. Native and portable tests compare the previous validator against valid
and corrupted ownership lists, including a cycle and a bad record after the
first batch (`build/i386-backing-batches-test-v1.log`,
`build/i386-backing-batches-source-test-v1.log`). The task-heap lifecycle suite,
both bootstrap generations, and the native cross-build/386 audit pass
(`build/i386-backing-batches-task-heaps-v1.log`,
`build/i386-backing-batches-rebuild-v1.log`,
`build/i386-backing-batches-cross-v1`). The 8 MiB drive-fields smoke also
passes (`build/i386-backing-batches-smoke-v1`).

The extended profile reads actual backing-region counts. It passed with 56,
102, 148 and 194 regions for 1,600, 3,200, 4,800 and 6,400 lines respectively
(`build/i386-bible-load-batches-large-v1`). At 3,200 lines, the same fixture on
both images measured 102 regions: the prior image took 100.6 seconds total,
including 74.1 seconds cleanup, while the batched image took 50.4 seconds,
including 26.2 seconds cleanup (`build/i386-bible-load-batches-control-v1`,
`build/i386-bible-load-batches-candidate-v1`). Another full-file guest was
active during these QEMU runs, and the timings are approximate, not hardware
benchmarks. The 6,400-line batched case took 157.5 seconds total. This removes
the fixed fallback boundary but does not establish full-file completion or
linear scaling.

The Memory 36 full-content image passed the cross-build and 386 audit
(`build/i386-backing-batches-full-cross-v1`). The complete Bible-link test on
that image timed out in its first link at the 20-minute command limit, with
unchanged inputs (`build/i386-doc-bible-link-full-batches-v1`); it is independent
of these bounded tests.

The Memory 36 16 MiB diagnostic also passed its initial isolated memory probe
and then reached the same prior-image `PublicTask.HH` failure
(`build/i386-backing-batches-diagnostics-v1`); the full diagnostic remains
failed. The 8 MiB drive-fields smoke passed with unchanged inputs
(`build/i386-backing-batches-smoke-v1`).

A subsequent task-header correction resolved the 16 MiB diagnostic's
`PublicTask.HH` failure; the full functional diagnostic passes on the updated
image (`build/i386-public-task-default-diagnostics-v1`). The earlier 8 MiB
diagnostic heap exhaustion remains a separate, unresolved resource limit. See
[public headers](i386-public-headers.md).

The 8 MiB failure occurs while the diagnostic compiles the actual two-source
native bundle, during frontend intermediate-code allocation. A QMP-paused
sample of the same phase in the passing 16 MiB diagnostic observed bootstrap
heap use of up to 6,816,232 bytes across 11 samples
(`build/i386-diagnostic-bundle-heap-16m-v1`). The 8 MiB bootstrap arena is
6,682,624 bytes, so the observed use alone exceeds it by 133,608 bytes; the
actual phase peak may be higher. The heap's lifetime peak is not a useful
phase peak here because earlier diagnostic tests deliberately exhaust it.
`tools/profile-i386-bundle-heap.py` records these counters without modifying the
input disk. This sample identifies a resource gap, not a timing measurement or
an 8 MiB diagnostic pass.

An optional heap snapshot in the profiler checks the physical block chain and
its allocation totals against the sampled counters. In a second 16 MiB run,
the highest sampled use was 6,819,560 bytes; that snapshot included 2,424
allocations requesting 132 bytes each, or 319,968 requested bytes in total
(`build/i386-diagnostic-bundle-histogram-16m-v1`). Frontend intermediate-code
nodes use this request size, but the histogram alone does not prove the owner
of each allocation or which nodes can safely be reclaimed. Inputs were
unchanged and the native bundle diagnostic passed.

`tools/profile-i386-bible-cleanup.py` also accepts `--lines` to sample cleanup
for other prefixes of the real Bible. A 6,400-line run on the batched validator
passed with unchanged inputs and observed 194 backing regions. Of 555
QMP-paused cleanup samples, 503 landed in `I386MemBackingValid`, called through
`I386MemBackingTrim` and `MemoryFree`
(`build/i386-bible-cleanup-batches-6400-v1`). These samples identify hot code;
they are not timing qualification.

## Larger batches and gap sorting

The next candidate raises the private validation batch from 64 to 256 region
addresses and sorts each batch with an in-place gap sort. Validation still
checks the complete heap and every owned region under interrupt exclusion;
longer lists continue through additional batches. The private scratch array
grows by 768 bytes. The gap sort avoids the many shifts observed for the
previous insertion sort on reversed region order.

Both compiler rebuild generations, native and portable heap suites, the
task-heap lifecycle suite, and the minimal and full-content cross-builds with
386 audits pass (`build/i386-backing-gap256-rebuild-v1.log`,
`build/i386-backing-gap256-test-v1.log`,
`build/i386-backing-gap256-source-test-v1.log`,
`build/i386-backing-gap256-task-heaps-v1.log`,
`build/i386-backing-gap256-cross-v1`,
`build/i386-backing-gap256-full-cross-v1`). The heap suite compares the
validator to the earlier independent oracle and tests a corrupted record and
cycle beyond the 256-region boundary. The 8 MiB drive-fields smoke also passes
with unchanged inputs (`build/i386-backing-gap256-smoke-v1`). The bounded Bible
performance profile passed with unchanged inputs at 56 and 102 regions
(`build/i386-bible-load-gap256-medium-v1`). At 3,200 lines it measured 32.4
seconds total and 12.8 seconds cleanup, versus 50.4 and 26.2 seconds for the
earlier 64-region-batch image with the same region count
(`build/i386-bible-load-batches-candidate-v1`). Both measurements overlapped
other QEMU guests and are approximate, not a hardware benchmark. The complete
Bible-link test on the full-content gap-sort image timed out at its 20-minute
command limit with unchanged inputs (`build/i386-doc-bible-link-full-gap256-v1`);
the bounded result does not establish full-file completion.

The larger 6,400-line profile also passes on the gap-sort image with unchanged
inputs and 194 regions (`build/i386-bible-load-gap256-large-v1`): it observed
106.2 seconds total, including 47.7 seconds cleanup. The earlier 64-entry batch
measured 157.5 seconds total and 90.8 seconds cleanup
(`build/i386-bible-load-batches-large-v1`). An experimental 256-entry
insertion-sort image instead measured 336.7 and 238.1 seconds
(`build/i386-bible-load-batch256-large-v1`), showing why a larger batch alone
is insufficient. These runs overlapped other guests and their timings are
approximate.

At 3,200 lines, a subsequent QMP-paused cleanup profile on the gap-sort image
passed with unchanged inputs. It recorded 46 of 65 samples in
`I386MemBackingValid` and another 10 in `I386MemPoolValid`
(`build/i386-bible-cleanup-gap256-3200-v1`). The most frequent sampled
instructions in the validator precede its hand-written heap walk and lie in
the generated sorting code. This identifies a remaining optimization target;
the sample is not a timing measurement.

## 386 gap sort

The next candidate implements the same bounded gap sort using 386 instructions
and byte offsets; guest-source builds retain the portable loop. The native and
portable heap suites compare valid and corrupted ownership lists with the
independent oracle, including a mixed address order and a cycle beyond the
batch boundary (`build/i386-backing-asm-sort-mixed-test-v1.log`,
`build/i386-backing-asm-sort-mixed-source-test-v1.log`). Both rebuild
generations, the task-heap lifecycle suite, and the minimal native cross-build
and 386 audit pass (`build/i386-backing-asm-sort-rebuild-v3.log`,
`build/i386-backing-asm-sort-task-heaps-v3.log`,
`build/i386-backing-asm-sort-cross-v3`). The full-content cross-build and 386
audit also pass (`build/i386-backing-asm-sort-full-cross-v1`); its full
Bible-link test timed out at the 20-minute command limit with unchanged inputs
(`build/i386-doc-bible-link-full-asm-sort-v1`). The 8 MiB drive-fields smoke passes with unchanged
inputs (`build/i386-backing-asm-sort-smoke-v1`). The bounded Bible profile
passes with unchanged inputs at 56 and 102 regions
(`build/i386-bible-load-asm-sort-medium-v1`). At 3,200 lines, it observed
30.3 seconds total and 10.6 seconds cleanup, compared with 32.4 and 12.8
seconds for the portable gap sort on the prior image. Both runs overlapped
other guests and are approximate. Neither establishes full-file completion.
The larger 6,400-line profile also passes with unchanged inputs and 194
regions (`build/i386-bible-load-asm-sort-large-v1`): it observed 89.4 seconds
total and 36.8 seconds cleanup, compared with 106.2 and 47.7 seconds for the
prior gap-sort image. The guests overlapped other work, so this is likewise an
approximate QEMU comparison.

The 3,200-line cleanup sampler also passes with unchanged inputs on the 386
sort image (`build/i386-bible-cleanup-asm-sort-3200-v1`): 32 of 54 samples
were in `I386MemBackingValid`, 11 in `I386MemPoolValid`, and 10 in the heap
chain validator. This remains a statistical sample rather than a timing test;
it shows that backing validation still warrants investigation.

## Full-link instruction sample

`tools/profile-i386-bible-link.py` samples the first actual full-content Bible
link lookup for a bounded period using a private image and QMP pauses. It does
not require that lookup to finish and does not qualify its result or timing.
On the 386-sort full-content image, a 90-second sample passed with unchanged
inputs and recorded 413 instruction pointers before the first lookup ended
(`build/i386-bible-link-sample-asm-sort-v1`). Of these, 343 were in the window
worker's text rendering, planar conversion, or VGA presentation; 50 were in
the kernel heap chain validator. The sample covers all scheduled guest tasks,
not just the lookup task, and other QEMU guests ran concurrently. It identifies
window presentation as a substantial observed cost but does not by itself
prove why the full lookup has not completed.

## Planar byte reversal

The next candidate replaces the three bit-swapping operations per VGA plane
byte with a 256-byte reversal table. It retains the same range checks, plane
selection, row bounds, and writes. The expanded independent VGA oracle tests
all byte values on each plane, partial rows, invalid arguments, and the full
displayed image; it passes before and after the change
(`build/i386-vga-reverse-table-baseline-v1.log`,
`build/i386-vga-reverse-table-test-v1.log`). Both compiler rebuild generations,
minimal and full-content cross-builds, and 386 audits pass. The 8 MiB
drive-fields smoke and public graphics-text contract pass with unchanged inputs
(`build/i386-vga-reverse-table-smoke-v1`,
`build/i386-vga-reverse-table-graphics-text-v1`). A 90-second full-link sample
passed with unchanged inputs but did not complete the lookup
(`build/i386-bible-link-sample-vga-reverse-v1`); 145 of 413 samples landed in
VGA upload, compared with 152 of 413 in the earlier sample. Those samples
include every guest task and do not establish a timing improvement. Neither
result establishes full-link completion. Paired 64 MiB graphics sessions passed
all 12 commands and exact VGA checkpoints with unchanged source images
(`build/i386-vga-reverse-table-graphics-v2`,
`build/i386-vga-reverse-table-graphics-control-v2`). Their four frame demos reported
440 ms each on the candidate versus 480, 460, 470 and 470 ms on the control.
These are guest-jiffy measurements while other QEMU guests were active; the
timings are approximate, not a hardware benchmark.
The full Bible-link test on the table image timed out at its 20-minute command
limit with unchanged inputs (`build/i386-doc-bible-link-full-vga-reverse-v1`).

## Pointer-based planar upload

A follow-up advances source and VGA pointers with a bounded U32
count instead of indexing both buffers with a wide loop counter. The existing
full-range pointer checks still precede all writes; the test also checks the
untouched row after a partial upload. Both compiler rebuild generations, the
native VGA oracle, and minimal and full-content cross-builds with 386 audits
pass (`build/i386-vga-pointer-rebuild-v1.log`,
`build/i386-vga-pointer-test-v1.log`, `build/i386-vga-pointer-cross-v1`,
`build/i386-vga-pointer-full-cross-v1`). The 8 MiB smoke passes with unchanged
inputs (`build/i386-vga-pointer-smoke-v1`). A 90-second full-link sampler passes
with unchanged inputs without completing the lookup
(`build/i386-bible-link-sample-vga-pointer-v1`): 109 of 410 samples were in
VGA upload, versus 145 of 413 on the prior image. Samples cover all scheduled
tasks and are not timing measurements. Paired graphics sessions passed all 12
commands and exact VGA checkpoints with unchanged source images
(`build/i386-vga-pointer-graphics-v1`, `build/i386-vga-pointer-control-v1`).
Their four frame demos measured 410, 410, 410 and 420 ms on the pointer loop,
versus 450, 440, 440 and 450 ms on the indexed control. Other QEMU guests
overlapped these guest-jiffy measurements, so the timings are approximate. The
full-link completion test timed out at its 20-minute command limit with
unchanged inputs (`build/i386-doc-bible-link-full-vga-pointer-v1`).

## Fully covered text backgrounds

When text has no pan or hidden edge, its background pass writes every pixel;
the renderer skips the preceding full-surface zero fill only in that case.
Panned or hidden-edge frames retain the clear. The original-renderer oracle
now poisons its destination before every comparison, including the unpanned
case. The unchanged baseline and candidate both pass all twelve original
blink/pan/hide comparisons (`build/i386-text-clear-baseline-v1.log`,
`build/i386-text-clear-cross-v1.log`). Both rebuild generations and the
minimal and full-content cross-builds with 386 audits pass
(`build/i386-text-clear-rebuild-v1.log`, `build/i386-text-clear-cross-v1`,
`build/i386-text-clear-full-cross-v1`). The 8 MiB smoke passes with unchanged
inputs (`build/i386-text-clear-smoke-v1`). Paired 64 MiB graphics sessions
passed all 12 commands and exact VGA checkpoints with unchanged source images
(`build/i386-text-clear-graphics-v1`, `build/i386-text-clear-control-v1`).
Their four frame demos measured 380, 370, 400 and 410 ms on the candidate,
versus 400, 410, 410 and 400 ms on the control. Other QEMU guests overlapped
these guest-jiffy measurements, so they are approximate. The full Bible-link
test timed out at its 20-minute command limit with unchanged inputs
(`build/i386-doc-bible-link-full-text-clear-v1`).

## Wider text-background stores

The renderer fills each eight-pixel background row with two U32 stores,
while retaining the separate foreground pass and the prior pan and clipping
logic. The original-renderer oracle now uses an unaligned, poisoned destination
with guard bytes; the baseline and candidate pass all twelve blink/pan/hide
comparisons (`build/i386-text-fill-baseline-v1.log`,
`build/i386-text-fill-cross-v1.log`). Both compiler rebuild generations and
the minimal and full-content cross-builds with 386 audits pass
(`build/i386-text-fill-rebuild-v1.log`, `build/i386-text-fill-cross-v1`,
`build/i386-text-fill-full-cross-v1`). The 8 MiB smoke passes with unchanged
inputs (`build/i386-text-fill-smoke-v1`). Paired 64 MiB graphics sessions pass
all 12 commands and exact VGA checkpoints with unchanged source images
(`build/i386-text-fill-graphics-v1`, `build/i386-text-fill-control-v1`). Their
four frame demos measured 330, 360, 350 and 370 ms, versus 380, 380, 420 and
410 ms on the control. Other QEMU guests overlapped these guest-jiffy
measurements, so the timings are approximate. The full Bible-link test timed
out at its 20-minute command limit with unchanged inputs
(`build/i386-doc-bible-link-full-text-fill-v1`).

A 90-second full-link sampler on the wider-store image passed with unchanged
inputs but did not complete the lookup (`build/i386-bible-link-sample-text-fill-v1`).
Of 413 samples, 131 landed in VGA upload, 75 in text rendering, and 71 in the
heap chain validator. This samples every scheduled guest task while other QEMU
guests run and is not an end-to-end timing or completion result.

## Blank glyph rows

The renderer skips the per-pixel foreground loop when the resolved glyph
row is zero, after applying underline. It does not assume a particular font or
character is blank. The original-renderer oracle explicitly includes blank and
underlined cells and passes on the baseline and candidate with an unaligned,
poisoned, guarded destination (`build/i386-text-blank-baseline-v1.log`,
`build/i386-text-blank-cross-v1.log`). Both rebuild generations, minimal and
full-content cross-builds, and 386 audits pass
(`build/i386-text-blank-rebuild-v1.log`, `build/i386-text-blank-cross-v1`,
`build/i386-text-blank-full-cross-v1`). The 8 MiB smoke passes with unchanged
inputs (`build/i386-text-blank-smoke-v1`). A 90-second full-link sample passes
with unchanged inputs without completing the lookup
(`build/i386-bible-link-sample-text-blank-v1`): 33 of 411 samples landed in
text rendering, compared with 75 of 413 on the prior image. These samples cover
all guest tasks and are not timing measurements. Paired 64 MiB graphics
sessions pass all 12 commands and exact VGA checkpoints with unchanged source
images (`build/i386-text-blank-graphics-v1`,
`build/i386-text-blank-control-v1`). Their four frame demos measured 320, 320,
360 and 350 ms, versus 320, 330, 360 and 360 ms for the control. Other QEMU
guests overlapped these guest-jiffy measurements; they show similar synthetic
frame times and are not a hardware benchmark. The full-link completion test
timed out at its 20-minute command limit with unchanged inputs
(`build/i386-doc-bible-link-full-text-blank-v1`).

The sampler also reads the exported window-manager update counter at the start
and end of its sampling window. Paired 90-second full-link samples passed with
unchanged inputs and neither completed the lookup
(`build/i386-bible-link-update-blank-v1`,
`build/i386-bible-link-update-control-v1`). The blank-row image completed 341
window updates in 90.1 seconds and the control completed 310 in 90.0 seconds.
Both guests ran concurrently and were paused for QMP samples; this is a
comparative diagnostic, not a full-link completion or hardware benchmark.

The sampler's `--pause-window-manager` mode is an explicitly diagnostic-only
way to inspect the lookup without normal refresh work. It suspends the worker
and submits the lookup in the same command, then verifies that its update
counter stays unchanged. A 90-second run passed with unchanged inputs, zero
window updates, and no completed lookup
(`build/i386-bible-link-suspended-blank-v3`). Of 411 samples, 130 landed in
free-span insertion during document allocation and 151 in the bootstrap heap
chain validator; several of the latter stacks belonged to keyboard work. This
is not a normal-desktop acceptance test or a direct timing measurement.

## Cached free-span consolidation (unqualified candidate)

The allocation path previously inserted each cached span into an
address-sorted list by walking from its head. The allocator joins the existing
free list and size buckets in the candidate, sorts the linked spans with a bottom-up merge sort
using constant auxiliary storage, then coalesces adjacent spans in one pass.
The heap remains locked throughout; the sorted result and adjacent-span merging
match the previous implementation for valid lists.

An independent copy of the previous algorithm agrees on ordered, reversed,
shuffled, fragmented, varied-size, and cross-bucket fixtures with up to 257
spans in both native and
portable heap tests (`build/i386-cache-mergesort-baseline-v3.log`,
`build/i386-cache-mergesort-baseline-source-v3.log`,
`build/i386-cache-mergesort-test-v1.log`,
`build/i386-cache-mergesort-source-test-v1.log`,
`build/i386-cache-mergesort-varied-test-v1.log`,
`build/i386-cache-mergesort-varied-source-test-v1.log`,
`build/i386-cache-mergesort-257-test-v1.log`,
`build/i386-cache-mergesort-257-source-test-v1.log`). Both rebuild generations,
the public heap and task-heap suites, and minimal and full-content cross-builds
with 386 audits pass (`build/i386-cache-mergesort-rebuild-v1.log`,
`build/i386-cache-mergesort-public-test-v1.log`,
`build/i386-cache-mergesort-public-source-test-v1.log`,
`build/i386-cache-mergesort-task-heaps-v1.log`,
`build/i386-cache-mergesort-cross-v1`,
`build/i386-cache-mergesort-full-cross-v1`). The 8 MiB smoke passes with
unchanged inputs (`build/i386-cache-mergesort-smoke-v1`). The bounded Bible
profile passes at 56 and 102 regions with unchanged inputs
(`build/i386-cache-mergesort-bible-medium-v1`). The diagnostic-only suspended
window-manager sample also passes with unchanged inputs and zero updates
(`build/i386-cache-mergesort-bible-isolated-v1`): eight of 412 samples landed
in the new merge function, versus 130 of 411 in the old insertion function.
The lookup did not complete during either sample, and their distributions are
not direct timings. The bounded control also passes with unchanged inputs
(`build/i386-cache-mergesort-bible-control-v1`): at 3,200 lines, the candidate
measured 21.7 seconds total versus 24.9 seconds on the preceding image, both
with 102 regions. Other QEMU guests overlapped the runs, so these elapsed times
are approximate. A 16 MiB non-diagnostic startup and retained-state resource
probe passes with unchanged inputs (`build/i386-cache-mergesort-startup16-v1`).
The 16 MiB diagnostic passed its startup probes but failed the initial
console-screen check before interactive commands on two runs; input hashes
were unchanged (`build/i386-cache-mergesort-diagnostics-v1`,
`build/i386-cache-mergesort-diagnostics-v2`). A source-matched control on the
preceding image passed the complete 16 MiB diagnostic with unchanged inputs
(`build/i386-cache-mergesort-diagnostics-control-v2`), so the candidate remains
unqualified. Extending the initial wait to 180 seconds still failed later at
the command-typing preflight (`build/i386-cache-mergesort-diagnostics-longwait-v1`).
Paired 90-second post-startup samples recorded four window updates for the
candidate and 348 for the control, with most candidate samples in graphics
compositing (`build/i386-cache-diag-prompt-candidate-v1`,
`build/i386-cache-diag-prompt-control-v1`). These are samples, not a causal
explanation. Separate snapshots found distinct frame and persistent buffers,
and the persistent overlay was fully transparent in both images
(`build/i386-cache-diag-surfaces-candidate-v1`,
`build/i386-cache-diag-surfaces-control-v1`). The cause of the diagnostic
regression remains unresolved. Paired 30-second samples of the live
`DCBlotColor8` stack locals observed the expected 307,200-pixel loop bound in
every captured compositor sample in both images. The candidate's loop
advanced about 6,000 pixels between successive 0.2-second samples and its
window completed one update; the control completed 116 updates in the same
sampling duration (`build/i386-cache-diag-locals-candidate-v1`,
`build/i386-cache-diag-locals-control-v1`). Inputs were unchanged. This
identifies slow execution in the candidate without establishing its cause.
An additional paired 12-second sample recorded zero candidate updates and 47
control updates. Captured compositor frames used distinct writable stack
addresses, and sampled control registers showed protected mode with paging
disabled in both guests (`build/i386-cache-diag-registers-candidate-v1`,
`build/i386-cache-diag-registers-control-v1`). Inputs were unchanged; these
observations do not rule out a memory-layout or emulation effect.
In a further paired 20-second run, the live 848-byte compositor function
matched byte for byte between the images. QEMU reported zero translation-block
invalidations during both sampling intervals, while the candidate completed
zero window updates and the control 77 (`build/i386-cache-diag-jit-candidate-v1`,
`build/i386-cache-diag-jit-control-v1`). Both runs preserved their inputs.
This does not support translation-block invalidation churn as the slowdown's
cause; the root cause remains open.
An isolated multiboot microbenchmark executed the captured compositor bytes
ten times with the candidate and control code, stack, and graphics-buffer
addresses. Candidate, control, and two mixed placements each completed in
0.46–0.48 seconds (`build/cache-layout-bench.asm`,
`build/cache-layout-link.ld`, `build/cache-layout-*.elf`). This benchmark has
interrupts disabled and does not reproduce the diagnostic guest's task or
device state; it shows only that the recorded address shifts alone did not
reproduce the slowdown.
The same isolated benchmark with a working 1 kHz timer interrupt also
completed ten loops in about 0.50 seconds in both layouts
(`build/cache-layout-irq-bench.asm`, `build/cache-layout-irq-*.elf`). It does
not reproduce the complete guest interrupt handlers or scheduler.
Host-side debugger samples taken during paired diagnostic startups found
`tb_invalidate_phys_range_fast` in five of twelve candidate samples and none
of twelve control samples; related dirty-page and tree-lookup paths also
appeared in the candidate. The candidate completed zero window updates versus
66 for the control during the surrounding capture
(`build/i386-cache-diag-host-candidate-v1`,
`build/i386-cache-diag-host-control-v1`). Both inputs were unchanged. These
samples suggest repeated code-page write checks even though no translation
blocks were actually invalidated. A follow-up captured QEMU's checked write
addresses between `0x3d404c` and `0x3d409c`, within the active window-worker
stack page at `0x3d4000` (`build/i386-cache-diag-host-page-candidate-v1`).
Its inputs were unchanged and it completed no window updates during sampling.
The source of the code-page sharing remains under investigation.
A temporary isolated worktree inserted a 4 KiB local stack gap in the window
worker. Its two bootstrap generations and 386 cross-build passed; the sampled
diagnostic image was byte-identical to the audited cross-build image. The
compositor stack moved to page `0x3d3000`, and the guest completed 117 window
updates in 30 seconds with unchanged inputs
(`build/i386-cache-stack-gap-diag-sample-v1`). This compares with one update
for the original candidate and 116 for the preceding-image control in the
earlier 30-second paired samples. The gap is an experiment, consumes stack
space, and is not a proposed production fix. The full 16 MiB diagnostic then
passed all nine interactive checks, 22 publication cases, and 28 program
publication cases; recorded input hashes were unchanged
(`build/i386-cache-stack-gap-diagnostics-v1`). A filtered QEMU translation
trace recorded 57 guest code blocks beginning on the original `0x3d4000`
stack page during startup (`build/i386-cache-diag-stack-code-v1`), before the
window worker used it. This supports a page-sharing explanation, though the
source of every translated block and a general fix remain to be established.
The current task-allocation candidate instead page-aligns each spawned stack
and reserves complete zeroed pages, retaining the requested usable size and
placing a private heap after the reservation. Native and retained task
lifecycle tests, public task heaps, both bootstrap generations, minimal and
full-content cross-builds, and the 16 MiB diagnostic pass
(`build/i386-task-page-alignment-native-v5.log`,
`build/i386-task-page-alignment-retained-v1.log`,
`build/i386-task-page-alignment-heaps-v3.log`,
`build/i386-task-page-alignment-rebuild-v1.log`,
`build/i386-task-page-alignment-cross-v1`,
`build/i386-task-page-alignment-full-cross-v1`,
`build/i386-task-page-alignment-diagnostics-v1`). The fixed task test arenas
were enlarged for the extra reservation. In isolated 8 MiB startup runs the
candidate took 76.7 seconds and the source-matched prior image took 77.0
seconds; both completed their interactive checks but failed the 60-second
startup gate with unchanged inputs (`build/i386-task-page-alignment-smoke-v2`,
`build/i386-task-page-control-smoke-v1`). Full qualification remains open.
The normal
full-link test timed out at its 20-minute command limit with unchanged inputs
(`build/i386-cache-mergesort-bible-full-v1`).

## Unrolled planar upload experiment

An experimental candidate processed four source bytes per loop iteration while keeping
four individual byte writes to VGA. Each validated row is 80 bytes, so the
bounded upload length is divisible by four. Both rebuild generations, the
native VGA oracle, and minimal and full-content cross-builds with 386 audits
pass (`build/i386-vga-unroll-rebuild-v1.log`,
`build/i386-vga-unroll-test-v1.log`, `build/i386-vga-unroll-cross-v1`,
`build/i386-vga-unroll-full-cross-v1`). The 8 MiB smoke passes with unchanged
inputs (`build/i386-vga-unroll-smoke-v1`). Paired graphics sessions pass all 12
commands and exact VGA checkpoints with unchanged source images
(`build/i386-vga-unroll-graphics-v1`, `build/i386-vga-unroll-control-v1`).
Candidate frames measured 330, 330, 370 and 370 ms versus 330, 330, 360 and
360 ms on the control. A 90-second full-link sample passed with unchanged
inputs without completing the lookup, recording 292 window updates
(`build/i386-bible-link-update-unroll-v1`); an earlier, separately timed control
recorded 341 (`build/i386-bible-link-update-blank-v1`). These QEMU runs
overlapped other guests and do not prove a regression, but provide no evidence
of a gain. The unrolled code was therefore discarded. Its full-link test timed
out at the 20-minute command limit with unchanged inputs
(`build/i386-doc-bible-link-full-vga-unroll-v1`).
