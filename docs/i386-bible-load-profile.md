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
Bible-link test is running. The 8 MiB drive-fields smoke passes with unchanged
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
