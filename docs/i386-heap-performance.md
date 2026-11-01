# Native bootstrap heap validation cost

## Module lookup counter experiment (2026-10-31)

A fresh normal-boot sample of the low-task-arena image recorded 251
root-header samples in `I386HeapScanSelect` and 60 foundation samples in
`I386FindSymbol` (`build/i386-low-task-boot-profile-v1`). Sampling pauses the
guest and does not measure startup time. An experiment changed the validated
loader fallback scan's loop counters and image offset to U32 while retaining
full duplicate detection. Both bootstrap generations, the native and
portable-index loader corpora, and the native cross-build/386 audit passed
(`build/i386-symbol-scan-u32-rebuild-v1.log`,
`build/i386-symbol-scan-u32-native-v2.log`,
`build/i386-symbol-scan-u32-portable-v2.log`,
`build/i386-symbol-scan-u32-cross-v1`). The initial native run requested a
rebuild; the initial portable run collided with a concurrent runner's shared
build directory, and the sequential rerun passed.

An isolated 8 MiB run completed all nine functional/VGA checks but missed the
60-second gate at 63.206 seconds (`build/i386-symbol-scan-u32-startup-v1`),
versus 63.500 seconds for the preceding image
(`build/i386-low-task-startup-isolated-v1`). This single pair does not establish
a useful speedup, so the experiment was discarded. The startup gate and
C1–C5 remain open.

## Single-scan free experiment (2026-10-31)

An experimental free path captured the preceding free block during the full
heap validation, avoiding a second search before coalescing. An independent
copy of the previous free algorithm and the candidate agree across all 24
four-block free orders, invalid interior pointers and byte-for-byte resulting
arenas. Both native and portable heap tests, task lifecycle, public heap,
allocation cache, both rebuild generations, minimal and full-content 386
cross-builds, and the complete 16 MiB diagnostic passed
(`build/i386-heap-free-single-native-v2.log`,
`build/i386-heap-free-single-source-v2.log`,
`build/i386-heap-free-single-tasks-v1.log`,
`build/i386-heap-free-single-public-v1.log`,
`build/i386-heap-free-single-cache-v1.log`,
`build/i386-heap-free-single-rebuild-v1.log`,
`build/i386-heap-free-single-cross-v1`,
`build/i386-heap-free-single-full-cross-v1`,
`build/i386-heap-free-single-diagnostics-v1`). The diagnostic inputs were
unchanged. The initial fixture used unsupported `continue` syntax and failed
to compile; the corrected fixture passed on the prior implementation first
(`build/i386-heap-free-single-baseline-v1.log`,
`build/i386-heap-free-single-baseline-v2.log`,
`build/i386-heap-free-single-baseline-source-v2.log`).

Two sequential isolated 8 MiB comparisons measured 66.1 and 65.7 seconds for
the candidate versus 65.1 and 64.9 for the source-matched control. All four
runs completed nine checks, retained unchanged inputs and missed the
60-second gate (`build/i386-heap-free-single-smoke-v1`,
`build/i386-heap-free-single-control-v1`,
`build/i386-heap-free-single-smoke-v2`,
`build/i386-heap-free-single-control-v2`). The experiment was discarded for
lack of a measured gain. The byte-for-byte free/coalescing fixture remains and
passes on the restored native and portable implementations
(`build/i386-heap-free-single-final-native-v1.log`,
`build/i386-heap-free-single-final-source-v1.log`).

## Compiler-owner lookup candidate (2026-10-31)

A normal 8 MiB boot sample on the page-isolated task-stack image recorded 368
of 490 root-header samples in `I386HeapScanSelect`
(`build/i386-task-page-alignment-boot-profile-v1`). These paused samples are
not a timing measurement. The compiler-owner candidate keeps the complete
heap validation for the compiler control, then looks up the owner's symbol
scope by walking validated physical block boundaries under the same interrupt
exclusion. No heap mutation or callback occurs between the two checks. It
does not trust a header forged inside an allocation.

The task-symbol test covers an interior forged header, a corrupt later block,
and both interrupt states. It passes alongside lexer state, heap corruption,
task lifecycle, both bootstrap generations, minimal and full-content 386
cross-builds, and the complete 16 MiB diagnostic
(`build/i386-codeowner-scan-baseline-v2.log`,
`build/i386-codeowner-scan-tests-v1.log`, `build/i386-codeowner-scan-lex-v1.log`,
`build/i386-codeowner-scan-heap-v1.log`, `build/i386-codeowner-scan-tasks-v1.log`,
`build/i386-codeowner-scan-rebuild-v1.log`, `build/i386-codeowner-scan-cross-v1`,
`build/i386-codeowner-scan-full-cross-v1`, `build/i386-codeowner-scan-diagnostics-v1`).
The diagnostic's recorded input hashes were unchanged. An 8 MiB run completed
all nine functional checks with unchanged inputs but failed the 60-second gate
at 70.6 seconds (`build/i386-codeowner-scan-smoke-v1`); a full Bible-link guest
ran concurrently. The preceding page-isolated image took 76.7 seconds alone,
so these observations suggest a gain but are not a controlled timing comparison.
The 60-second gate and full C1–C5 qualification remain open.

## Lexer snapshot lookup candidate (2026-10-31)

Snapshot validation now performs one complete heap validation, then checks
its saved files and active files by walking the already validated block
boundaries under the same interrupt exclusion. The shared boundary-walk helper
is also used by compiler-owner validation. No heap mutation or callback
occurs between validation and the lookups.

The nested snapshot fixture checks forged interior saved-file and active-file
headers, a corrupt later block and interrupt restoration. The baseline passes
(`build/i386-lex-snapshot-scan-baseline-v1.log`). The first candidate run
exited without its expected runner output
(`build/i386-lex-snapshot-scan-boundary-v1.log`); replaying its runner image
and a complete fresh run passed (`build/i386-lex-snapshot-scan-boundary-v2.log`).
Task-symbol tests, both bootstrap generations, minimal and full-content
cross-builds and the full 16 MiB diagnostic also pass with recorded diagnostic
input hashes unchanged (`build/i386-lex-snapshot-scan-symbols-v1.log`,
`build/i386-lex-snapshot-scan-rebuild-v1.log`,
`build/i386-lex-snapshot-scan-cross-v1`,
`build/i386-lex-snapshot-scan-full-cross-v1`,
`build/i386-lex-snapshot-scan-diagnostics-v1`).

In sequential isolated 8 MiB runs the candidate took 66.6 seconds and the
source-matched preceding image took 70.6 seconds. Both completed all nine
interactive checks with unchanged inputs and failed the 60-second gate
(`build/i386-lex-snapshot-scan-smoke-v2`,
`build/i386-lex-snapshot-scan-control-v1`). The earlier concurrent candidate
run took 68.0 seconds (`build/i386-lex-snapshot-scan-smoke-v1`). C1–C5 and the
startup gate remain open.

A follow-up normal-boot sample on this image recorded 249 of 405 root-header
samples in `I386HeapScanSelect`, with another nine in the new known-size walk
(`build/i386-lex-snapshot-scan-boot-profile-v1`). These are paused statistical
samples, not call counts or timing measurements. Heap validation remains a
prominent startup cost.

An experimental guarded allocation combined token ownership verification and
first-fit selection into one complete heap scan. Native and portable heap
tests and the identifier fixture passed, but an isolated 8 MiB run took 66.5
seconds versus 65.0 seconds for the preceding image, with all nine checks
complete (`build/i386-ident-guard-heap-v2.log`,
`build/i386-ident-guard-heap-source-v2.log`,
`build/i386-ident-guard-ident-v3.log`, `build/i386-ident-guard-smoke-v2`,
`build/i386-lex-push-scan-smoke-v1`). The experiment was discarded. Its first
image also failed boot because the compiler loader lacked the new import
binding (`build/i386-ident-guard-smoke-v1`); a compiler-binding coverage check
was retained and verifies that declared imports are present in the kernel's
explicit binding list. Both measured startup runs missed the 60-second gate.

## Lexer push lookup candidate (2026-10-31)

On successful snapshot allocation, the allocator has validated and updated
the heap while interrupts remain excluded. Snapshot creation now uses the
same block-boundary walk to verify its active file and parents before the next
allocation, rather than repeating complete validations. The pop path retains
its complete validation after restoring caller-provided file state.

The forged-parent fixture passes before and after the change, along with the
snapshot-boundary and compiler-owner suites
(`build/i386-lex-push-scan-baseline-v1.log`,
`build/i386-lex-push-scan-boundary-v1.log`,
`build/i386-lex-push-scan-symbols-v1.log`). An initial rebuild correctly
rejected changed inputs after the pop optimization was removed; the fresh two
generations, minimal and full-content 386 cross-builds, and complete 16 MiB
diagnostic pass (`build/i386-lex-push-scan-rebuild-v1.log`,
`build/i386-lex-push-scan-rebuild-v2.log`, `build/i386-lex-push-scan-cross-v1`,
`build/i386-lex-push-scan-full-cross-v1`, `build/i386-lex-push-scan-diagnostics-v1`).
The diagnostic input hashes were unchanged. An isolated 8 MiB run completed
all nine interactive checks with unchanged inputs but failed the 60-second
gate at 65.0 seconds (`build/i386-lex-push-scan-smoke-v1`); the preceding
image took 66.6 seconds in the earlier isolated run. C1–C5 remain open.

Loading the complete document records at bce29e6 exposed a normal-startup
regression: 60.612 seconds on the QEMU/486 8 MiB profile, compared with 25.038
seconds before those records were published. Full diagnostic startup took
726.823 seconds. The public headers retained 169920 bytes.

## Measurement

`tools/profile-i386-boot.py` samples instruction pointers and up to five EBP
caller frames through QMP while a snapshot of the normal disk boots. It checks
the disk and module hashes against the native build manifest, resolves exported
function ranges, and groups samples by boot phase. The output records the image,
OS source and profiler hashes, raw samples, command line and grouped results.
Run it after `tools/build-i386-kernel.py --test`:

```
python3 tools/profile-i386-boot.py --out build/i386-boot-profile
```

Pausing the guest introduces overhead. These samples estimate where execution
time is spent; they are neither call/traversal counts nor a boot-time benchmark.
Caller frames sampled in prologues/epilogues may be incomplete. Use the normal
unpaused suite's timings to compare boot latency.

This run's baseline artifacts are in `build/i386-boot-stack-profile/`; optimized
samples are in `build/i386-boot-optimized-profile/`. Each contains `result.json`,
`samples.json`, the QEMU command and debug log. These build outputs are local
evidence; the tool and the measurements below are versioned.

On the document-enabled baseline, a run with caller sampling attributed 297 of
380 header-loading samples and 179 of 193 startup-source samples to
I386HeapValid. An earlier PC-only run independently found 288/373 and 180/192.
Frequent callers included control/task-owner validation from parser token and
allocation operations, identifier publication, and final publication/freeing.
These measurements establish full-chain validation as a major cost in this
workload; they do not establish that every compiler allocation should use the
same replacement policy.

## Bounded optimization

The bootstrap heap still validates its complete physical block chain on every
allocation, free and size query. Its validation loop now uses explicit 386
instructions instead of generated wide expression code. It keeps the HolyC
region/control checks and every block invariant: minimum/aligned/bounded spans,
reserved words, valid tags, requested length, no adjacent free blocks, and exact
used/allocation totals. It never exits early on finding a requested allocation.

Loop counters fit U32 because each span is checked against remaining arena bytes
before advancement. Used bytes are at most arena size; allocation count is at
most arena size divided by the minimum 24-byte block size. The existing wide
region check prevents pointer overflow and overlap with the control record.
The public API, allocation layout, requested-size meaning and ownership rules
are unchanged. No validation cache assumes that heap metadata remains unmodified.

The heap test retains the preceding HolyC validator as an independent oracle.
It compares 160 mutations across all four headers of a mixed allocated/free
chain and the control counters/signature. It checks arena immutability and
rejects allocation, free and size lookup when corruption lies after a valid
requested block. Existing coalescing, zero-sized allocation, exhaustion, churn,
public heap/backing and guard-byte tests still run.

## Inline assembly correctness

The first allocator run failed on a valid heap because a native conditional
branch immediately before inline assembly skipped its setup instructions.
Assembler labels appear before IC_ASM in the IR, but carry distinct byte offsets
inside that block. Adjacent-label forwarding had incorrectly merged the HolyC
entry label with the first internal assembler label.

The shared optimizer now preserves these boundaries for the i386 target.
Regression cases exercise both outcomes of a conditional before an assembly
prefix and branches to two distinct labels inside one assembly block. The x64
optimization policy remains unchanged. Heap tests, inline-assembly tests and
all 245 native function cases pass their instruction audits.

This optimization does not complete compiler allocation migration. Metadata and
working storage still use bootstrap arenas. Public task heaps must eventually
own those objects with explicit logical sizes, publication/rollback policies and
teardown; retain failure and corruption tests during that work. Full editor
latency, strict 386/no-387 and physical-machine performance remain unverified.

## Integrated result

| QEMU/486, 8 MiB | Document baseline | Optimized |
| --- | ---: | ---: |
| Normal startup | 60.612 s | 15.806 s |
| Diagnostic startup | 726.823 s | 137.386 s |
| Public-header retained heap | 169920 B | 169920 B |
| Kernel bytes | 388936 B | 386680 B |
| Bootstrap reservation headroom | 184 B | 2440 B |

The normal harness deadline is restored from 90 to 60 seconds. Diagnostics keep
the 1200-second allowance; the measured runtime above is independent of that
allowance. Normal boot with a damaged diagnostic probe completes in 15.907
seconds and passes its commands. The full suite passes 124 commands across 187
input lines, exact VGA output, all startup-source recovery cases and 17 module
rejection cases. Both x64 rebuild generations pass. CompilerRuntime remains ABI
42, now 1314240 image / 1314256 heap bytes; other service interfaces are unchanged.

A follow-up profile finds heap validation in 33/99 header and 15/30 startup
samples. Remaining samples include allocation, size and free scans, so bootstrap
allocator scaling remains a measured constraint. The short startup phase yields
few samples; these proportions are approximate and do not replace end-to-end
latency measurements. Full validation remains enabled in normal boot.

## Allocated-block hot path, 2026-10-16

The current desktop startup profile found I386HeapScanSelect in 181/241
root-header samples (`build/i386-c4-shared-lifecycle-boot-profile`). The normal
8 MiB workload completed its nine functional checks but missed the 60-second
startup gate. This follow-up keeps the whole physical chain scan, metadata and
control-counter checks, and mutation only after successful validation.

The assembly path now checks the common USED tag first, retains the previous-free
state in EBX, and uses LEA to calculate the payload bound without subtracting and
restoring the span. EBX is reloaded with the control pointer before final counter
checks. No arena layout, allocation size, stack size or API changed. The portable
validator remains unchanged. The first candidate incorrectly annotated the LEA
operand as U8; compilation rejected it. Correcting that annotation to U32 is
recorded alongside the preserved failed kernel and standalone compile artifacts:
`build/i386-c4-heap-hotloop-cross` and
`build/i386-c4-heap-hotloop-asm-compile-red`.

The corruption corpus adds adjacent free blocks whose requested lengths and
control counters are otherwise valid. Both the independent reference and native
validator must reject them, and allocation/free/size operations must leave arena
and control bytes untouched. Existing 160 header/control mutations, later-block
corruption, allocation, coalescing, exhaustion and alignment checks remain.

The assembly core, public heap/backing and high-placement suites pass at 8 MiB
in `build/i386-c4-heap-hotloop-{core,public,high}-green`, including instruction
audits. Independent reads of each compiler ISO verify 800 delivered Kernel,
Compiler, corruption-fixture and generated-target files. The portable path also
passes in `build/i386-c4-heap-hotloop-source-green`; it was run before correcting
the inactive assembly annotation, so that artifact is not a current whole-file
source-hash match. Its portable implementation and fixture are unchanged.

Both original bootstrap generations and
`build/i386-c4-heap-hotloop-fixed-cross` pass: 575128 kernel bytes, all 1484 source
and 24 build-input hashes matching, and the limited 96-BIOS/255-protected-mode
instruction audit. The fresh control uses an isolated d308b828 checkout and the
same prior immutable image, harness, 8 MiB RAM, 486,-fpu CPU, nine commands and
60-second threshold. It completes all functional checks but fails timing at
65.024112 seconds in `build/i386-c4-heap-hotloop-startup-control`. The candidate
passes the complete gate at 56.025820 seconds in
`build/i386-c4-heap-hotloop-startup-native`, including retained static state,
literals, arithmetic, graphics activation and exact text/graphics restoration.
No build-only provider loads. These are observed QEMU runs, not physical-386 or
full desktop/application/native-generation qualification; C1–C5 remain open.

## First-fit selection during complete validation, 2026-10-16

After integrating the original raw renderer, normal 8 MiB startup completed its
behavior checks but took 61.301742 seconds against the unchanged 60-second
limit. The source-pinned prior image passed at 57.137695 seconds. Statistical
profiles in build/i386-c4-raw-output-{boot-profile,prior-boot-profile} attribute
285/376 and 271/373 root-header samples to I386HeapScanSelect respectively.
These paused profiles identify the dominant cost; they do not establish the
cause of the difference between individual timing runs.

Ordinary I386HeapAlloc previously validated every block, then traversed the
arena again to locate its first fitting free block. It now asks the same
validator to remember the first fit during the complete validation pass. The
candidate is published only after all block invariants and both control totals
match. Allocation then splits or consumes that same first-fit block. High
placement retains last-fit selection. The public API, layout, request sizes,
zeroing, overflow checks, coalescing and all corruption checks are unchanged.
The assembly and portable implementations both implement this selection mode;
no validation cache or early exit replaces the whole-arena scan.

The independent corruption corpus retains its 160 mutations and adds an early
usable free hole followed by a corrupt later block. Allocation must reject it
without changing arena or control bytes; repairing the later block must allow
allocation at that exact first hole. Core, public, cache and high-placement
suites pass for both implementations at 8 MiB, with instruction audits, in
build/i386-c4-raw-heap-first-{core,public,cache,high} and their -source variants.
Independent RedSea reads of all eight compiler ISOs match 817 Kernel/Compiler,
fixture and generated-target files in each; delivered-source-audit.json records
the hashes. An initial test invocation correctly rejected stale bootstrap pins;
it supplied no execution evidence.

The fresh two-generation bootstrap and build/i386-c4-raw-heap-first-cross pass,
including the 96-BIOS/255-protected-mode instruction audit. All 1501 source and
24 build-input hashes match. The unpaused normal 8 MiB gate passes in
build/i386-c4-raw-heap-first-startup at 55.824419 seconds, with all nine commands,
exact VGA restoration and no build-only provider load. The 60-second threshold
is unchanged. All 13 frozen raw captures match in
build/i386-c4-raw-heap-first-native (17 commands); all eight diagnostic-print
cases pass in build/i386-c4-raw-heap-first-print (11 commands). Both run at
64 MiB with unchanged inputs. The 16 MiB diagnostic-startup suite fails after
the second timer tick in build/i386-c4-raw-heap-first-diagnostics. The matching
413273ed checkout and pre-optimization image also fail at this boundary in
build/i386-c4-raw-heap-first-prior-diagnostics. Their MemoryRuntime modules are
byte-identical; this is not a passing diagnostic gate.

The startup-memory observer now supports 8/16 MiB and records stopped registers
and bounded EBP return frames. Its 16 MiB capture in
build/i386-c4-raw-heap-first-diagnostic-stop has unchanged inputs and resolves
the failure to MemoryProbe+0x7e4, the empty-control guard in phase 1. Independent
reads of the saved memory and generated instruction offsets find used_u8s=16;
the only live span is the public allocation backing cur_dir="/", with its
owner equal to the task's actual heap control. The record is in
empty-heap-assumption.json. Allocating current-directory strings in the task
heap is expected behavior; the diagnostic's assumption predates that change.
The next correction must preserve live task allocations while exercising and
tearing down the isolated probe heap. It must retain the full probe and exact
restoration checks, not suppress phase 1 or its failure. The 16 MiB gate and
full C1-C5 qualification remain open.

## Free lookup during validation experiment (2026-11-01)

A new sampled profile of the popup-exit build
(`build/i386-popup-exit-boot-profile-v1`) found `I386HeapScanSelect` at 257 of
412 root-header samples and 30 of 51 startup-source samples. Sampling pauses
make this a location profile, not a timing measurement. Frequent stacks include
heap validation during `I386HeapFree`, which then performs a second walk to
find the block and its predecessor.

An experimental implementation remembered a matching used block's preceding
free block during the existing full validation pass and eliminated that
second walk. It retained full-chain/counter validation and did not mutate the
arena on a rejected pointer. Both native and portable heap-core suites passed,
including all 24 free-order parity comparisons and later-corruption rejection
(`build/i386-heap-free-single-core-v1.log`,
`build/i386-heap-free-single-source-v1.log`); public and high-placement suites,
both bootstrap generations, the full cross-build and 386 audit also passed
(`build/i386-heap-free-single-{public,high,rebuild}-v1.log`,
`build/i386-heap-free-single-cross-v1`).

The isolated 8 MiB startup passed all nine functional and VGA checks but took
67.921 seconds (`build/i386-heap-free-single-startup-8m-v1`), versus 66.213
seconds in the preceding isolated control; neither met the 60-second gate.
This pair does not establish a statistically significant slowdown, but it does
not justify the additional hot-loop work. The allocator change was reverted;
the exact experimental patch remains in
`build/i386-heap-free-single-v1.patch`. The profile, failed timing gate and
candidate tests do not close the startup or C1–C5 requirements.

## Compact loader symbol index (2026-11-01)

The paused profile of the popup-exit build recorded 59 of 212 foundation
samples in `I386FindSymbol`. ConsoleRuntime has 1,113 exports, so the former
512-slot scratch index often fell back to a full scan. The loader now stores
validated record pointers in 1,024 eight-byte slots, keeping the slot array's
8 KiB size. Each link also encodes its source-module ordinal; this preserves
identity for overlapping or repeated input buffers. Counts beyond the ordinal
encoding and buckets beyond capacity fall back to the original full scan.
Ambiguous matches also use that scan to preserve its last-match result.

Both native and portable loader corpora pass 40 cases, with differential tests
for mixed function/data exports, 1,024/1,025-entry capacity boundaries,
duplicates and ordinal encoding (`build/i386-index-compact-loader-v3.log`,
`build/i386-index-compact-portable-v3.log`). Both bootstrap generations and the
full cross-build with 386 audit pass (`build/i386-index-compact-rebuild-v3.log`,
`build/i386-index-compact-cross-v3`). The loader stack audit passes at
16,332 of 16,384 bytes, leaving 52 bytes of the declared bound
(`build/i386-index-compact-stack-v3`); this narrow remaining margin must be
rechecked for future loader changes. The complete 16 MiB diagnostic passes
(`build/i386-index-compact-diagnostics-v3`).

An isolated 8 MiB run passes all nine functional and VGA checks but misses the
60-second gate at 62.495 seconds (`build/i386-index-compact-startup-8m-v3`).
A source-matched isolated control took 69.377 seconds
(`build/i386-index-compact-control-8m-v2`); this single comparison is not a
statistical benchmark. The final candidate's paused profile recorded 19 of
177 foundation samples in `I386FindSymbol`, versus the previous 59 of 212
(`build/i386-index-compact-profile-v1`). Sampling is not a timing measure.
The first, larger-slot candidate exceeded the worker stack budget, and an
intermediate compact candidate lacked module identity for overlapping buffers;
neither was retained. Full C1–C5 qualification and the startup gate remain open.

## Module validation offset experiment (2026-11-01)

The compact-index boot profile sampled `I386ModuleValidParts` 28 times during
foundation startup. An experiment changed its bounded record-position locals
from I64 to U32 while retaining wide file-size validation and all range and
patch checks. Both bootstrap generations, 181 target validator cases, the
40-case native loader corpus, the full cross-build, the 386 audit and the
loader stack audit passed (`build/i386-module-offset-u32-rebuild-v1.log`,
`build/i386-module-offset-u32-check-v1.log`,
`build/i386-module-offset-u32-loader-v1.log`,
`build/i386-module-offset-u32-cross-v1`,
`build/i386-module-offset-u32-stack-v1`).

The isolated 8 MiB candidate completed all nine functional/VGA checks in
62.502 seconds (`build/i386-module-offset-u32-startup-v1`), essentially the
same as the prior candidate's 62.495 seconds; neither met the 60-second gate.
That pair does not establish a useful speedup, so the offset change was
reverted. Its patch is retained in `build/i386-module-offset-u32-v1.patch`.
The validator corpus retains five new U32-maximum record-offset rejection cases
for function, data, relative, address and named-pointer records. All 181 cases
pass again on the restored validator after both bootstrap generations
(`build/i386-module-offset-u32-restored-rebuild-v1.log`,
`build/i386-module-offset-u32-restored-check-v1.log`). C1–C5 remain open.

## Parser token ownership lookup (2026-11-01)

After `I386CmpCodeOwner` validates the complete heap under interrupt exclusion,
`I386ParserToken` now checks its existing string allocation by walking the
already validated block boundaries before releasing that exclusion. No heap
mutation or callback occurs between those checks. The helper requires a real
used block with the requested minimum size, so an interior forged header is
not accepted; the compiler service version is 75.

The task-symbol fixture checks the new lookup against an interior forged
header and minimum-size bounds in both interrupt states. It passes with the
lexer snapshot regression, both bootstrap generations, the full cross-build,
386 and loader-stack audits, the 16 MiB diagnostic and a 64 MiB asynchronous
popup regression (`build/i386-parser-token-known-symbols-v1.log`,
`build/i386-parser-token-known-lex-v1.log`,
`build/i386-parser-token-known-rebuild-v2.log`,
`build/i386-parser-token-known-cross-v1`,
`build/i386-parser-token-known-stack-v1`,
`build/i386-parser-token-known-diagnostics-v1`,
`build/i386-parser-token-known-popup-v1`).

Isolated 8 MiB candidate and source-matched control runs both completed their
nine functional/VGA checks but missed the 60-second gate at 61.394 and 62.295
seconds respectively (`build/i386-parser-token-known-startup-v1`,
`build/i386-parser-token-known-control-v1`). This single comparison does not
establish a statistically significant speedup. C1–C5 remain open.

## Parser allocation ownership experiment (2026-11-01)

A follow-up candidate reused the immediately preceding compiler-control heap
validation for `I386ParserSize` and `I386ParserTake`, adding a boundary-walk
helper that returned an allocation's requested size. Task-symbol and lexer
snapshot tests, both bootstrap generations, the full cross-build, 386 and
loader-stack audits passed (`build/i386-parser-ownership-known-symbols-v1.log`,
`build/i386-parser-ownership-known-lex-v1.log`,
`build/i386-parser-ownership-known-rebuild-v1.log`,
`build/i386-parser-ownership-known-cross-v1`,
`build/i386-parser-ownership-known-stack-v1`). The fixture checked the new
lookup against an interior forged header and its actual requested size.

An isolated 8 MiB run completed its nine functional/VGA checks in 61.394
seconds (`build/i386-parser-ownership-known-startup-v1`), indistinguishable at
three decimal places from the prior 61.394-second candidate. Neither met the
60-second gate. This single comparison does not establish a useful improvement,
so the additional helper and parser changes were reverted; the experimental
patch is in `build/i386-parser-ownership-known-v1.patch`. Full C1–C5
qualification remains open.

## Identifier publication combined-scan experiment (2026-11-01)

A fresh profile of the current image sampled `I386HeapScanSelect` in 259 of
401 root-header frames (`build/i386-copy-single-z-boot-profile-v1`). Forty of
those stacks included identifier publication, with separate scans for validating
the prior token, allocating its replacement, and freeing the prior token. These
paused samples locate work; they do not measure elapsed time.

A candidate combined the prior-token validity check and first-fit allocation
selection into one complete heap traversal. It retained the existing allocation
and out-of-memory behavior, including rejecting an interior forged header, a
zero-sized guard, and a later corrupted block before changing the heap. The
identifier and lexer-snapshot tests, portable heap core, both original rebuild
generations, native cross-build and 386 audit passed
(`build/i386-ident-guarded-cross-v2`). The 8 MiB startup candidate passed all
nine functional and exact-VGA checks in 61.095 seconds
(`build/i386-ident-guarded-startup-8m-v1`), compared with 62.402 seconds for
the preceding image (`build/i386-copy-single-z-startup-8m`). This single pair
is not sufficient evidence of a reliable improvement, and both miss the
60-second gate. The candidate was discarded; its patch is retained in
`build/i386-ident-guarded-v1.patch`.

The portable public-heap fixture did not execute: its compiled runner exceeded
its fixed 192 KiB transfer area by 614 bytes after the extra helper was added
(`build/i386-ident-guarded-heap-public-v1.log`). This is a test-transport
limit, not a passing or failing public-heap behavior result. The new zero-sized
identifier guard check is retained in the existing regression fixture; the
restored-source run is `build/i386-ident-guarded-restored-lex-v1.log`.
C1–C5 and the startup timing gate remain open.

## Publication ownership walk (2026-11-01)

During the bitmap-backed publication pass, `I386ClassTransferVisit` previously
walked the parser-allocation queue once to establish ownership and immediately
walked it again to obtain the bitmap position. It now obtains both from one
walk while the queue is held unchanged. Missing records, out-of-range slots,
lexer/control aliases and repeated selections remain rejection cases; no
scratch allocation or persistent index was added. The array-backed class
publication path still uses its existing ownership lookup.

Both original rebuild generations, the native task-symbol regression, full
cross-build and 386 audit pass (`build/i386-publish-one-walk-rebuild-v1.log`,
`build/i386-publish-one-walk-symbols-v1.log`,
`build/i386-publish-one-walk-cross-v1`). The 16 MiB diagnostic passes its
compiler publication and ownership probes, all nine interactive checks and
exact VGA (`build/i386-publish-one-walk-diagnostics-v1`). This does not prove
all possible malformed graphs or concurrent publication scenarios.

The candidate and a source-matched preceding-image control both completed all
nine functional and exact-VGA checks in isolated 8 MiB runs, taking 60.594 and
61.796 seconds respectively (`build/i386-publish-one-walk-startup-v1` and
`build/i386-publish-one-walk-control-v2`). This single pair does not establish
a stable timing improvement, and both miss the 60-second gate. The candidate's
source hash matches the final restored source. C1–C5 remain open.

## Free-specific validation pass

The current two-arena image's paused startup profile sampled
`I386HeapScanSelect` in 414 root-header samples, including 102 stacks through
`I386HeapFree` (`build/i386-fallback-boot-profile-v1`). The free path previously
validated the whole heap and then walked the chain again to locate the block.
It now has a dedicated validation pass that remembers the target and any
preceding free block while checking the complete chain and counters. It makes no
arena changes until the entire pass succeeds. Allocation and size-query scans
are unchanged.

The native and portable heap-core tests pass their free-order parity and
corruption cases (`build/i386-free-special-core-v2.log`,
`build/i386-free-special-source-v2.log`). The public-pool, multi-arena and
high-placement tests also pass (`build/i386-free-special-public-v2.log`,
`build/i386-free-special-public-source-v2.log`,
`build/i386-free-special-high-v2.log`). Both original rebuild generations,
native cross-build and 386 audit pass (`build/i386-free-special-rebuild-v2.log`,
`build/i386-free-special-cross-v2`). The 16 MiB diagnostic, full 8 MiB
sound-effects fixture and 8 MiB dual-arena task-accounting batch pass with
unchanged inputs (`build/i386-free-special-diagnostics-v1`,
`build/i386-free-special-effects-8m-v1`,
`build/i386-free-special-task-batch-8m-v1`).

An alternating isolated boot-to-prompt comparison measured control boots at
74.14 and 74.09 seconds and candidate boots at 72.98 and 73.38 seconds
(`build/i386-free-special-pair-v1`). The image manifests differ only in
`Kernel/I386/Heap.HC`, with identical recorded build inputs
(`build/i386-free-special-image-comparison.json`). This small four-run sample
shows a modest reduction on this host, not a general performance guarantee. The
candidate's separate full 8 MiB startup check completed its functional and VGA
checks in 72.98 seconds (`build/i386-free-special-startup-8m-v1`), still above
the 60-second gate. Full C1–C5 qualification remains open.

## Identifier validation and allocation revisited

The profile of the free-specific baseline still found `I386HeapScanSelect` in
309 root-header samples and `I386HeapFree` in 101 samples
(`build/i386-free-special-profile-v1`). These are statistical samples, not call
counts. The earlier identifier-publication candidate is now retained: when
replacing a token, one complete traversal validates the old payload and selects
the first fitting free block. No allocation occurs until the entire heap and
its counters have passed validation. Invalid ownership and allocation failure
remain distinct, and the existing interrupt exclusion covers the operation.

The identifier regression covers zero-sized and forged interior guards, later
heap corruption, successful replacement and allocation failure
(`build/i386-ident-guarded-new-lex.log`). Lexer snapshot, native and portable
heap-core, and native and portable public-heap regressions pass, as do both
original rebuild generations, the full cross-build and the 386 instruction
audit (`build/i386-ident-guarded-new-snapshot.log`,
`build/i386-ident-guarded-new-core.log`,
`build/i386-ident-guarded-new-core-source.log`,
`build/i386-ident-guarded-new-public.log`,
`build/i386-ident-guarded-new-public-source-v2.log`,
`build/i386-ident-guarded-new-rebuild.log` and
`build/i386-ident-guarded-new-cross`). The public fixture's loader allowance
was raised from 416 to 448 sectors, its already enforced maximum below the
first arena, to accommodate the portable helper.

An isolated alternating 8 MiB boot-to-prompt comparison measured the baseline
at 73.186 and 73.185 seconds and the candidate at 72.285 and 72.436 seconds
(`build/i386-ident-guarded-new-pair`). The image manifests differ in the five
identifier and heap source files changed for this experiment and in the build
and test scripts; the test script's fixture-size change does not enter the
kernel image. This four-run sample shows a modest host-specific reduction, not
a general performance guarantee. The result remains above the 60-second gate;
full C1–C5 qualification remains open.

The full 8 MiB startup run completed all nine functional checks and exact VGA,
but failed its 60-second timing assertion (`build/i386-ident-guarded-new-startup-8m`).
Its elapsed time was collected concurrently with other checks and is not used
for the comparison above. The 16 MiB diagnostic startup and the 8 MiB public
task-accounting batch both pass (`build/i386-ident-guarded-new-diagnostics`,
`build/i386-ident-guarded-new-task-batch`).

## Size-query validation pass

The native heap's size and validity queries now use a dedicated complete
validation traversal that does not consider free-block allocation candidates.
It retains the region and header checks, full-chain corruption detection,
used-byte and allocation-count checks, and exact payload matching. Allocation
selection remains on its existing path; portable source builds retain the
shared validator. This adds a second native traversal to maintain, so any future
validator changes must keep both paths in agreement.

Native and portable heap-core and public-pool tests pass, including malformed
metadata after the queried block; lexer and task-symbol regressions pass as well
(`build/i386-heap-query-scan-core.log`, `build/i386-heap-query-scan-source.log`,
`build/i386-heap-query-scan-public.log`,
`build/i386-heap-query-scan-public-source.log`,
`build/i386-heap-query-scan-lex.log` and
`build/i386-heap-query-scan-symbols.log`). Both original rebuild generations,
the full cross-build and 386 audit pass (`build/i386-heap-query-scan-rebuild.log`
and `build/i386-heap-query-scan-cross`).

An isolated alternating 8 MiB boot-to-prompt comparison measured the control at
72.380 and 72.226 seconds and the candidate at 71.624 and 71.953 seconds
(`build/i386-heap-query-scan-pair`). The image manifests differ only in
`Kernel/I386/Heap.HC`; recorded build inputs are identical. This small sample
shows a modest host-specific improvement, not a general performance guarantee.
The 60-second gate and C1–C5 remain open.

The full 8 MiB startup completed all nine functional and VGA checks but failed
the 60-second timing assertion (`build/i386-heap-query-scan-startup`). That
run overlapped other checks and is not part of the isolated comparison. The
16 MiB diagnostic and the 8 MiB task-accounting batch pass
(`build/i386-heap-query-scan-diag`, `build/i386-heap-query-scan-task`).
