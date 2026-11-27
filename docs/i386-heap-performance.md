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

A direct differential regression compares the query traversal with the
selection traversal for a null pointer and every byte from one byte before a
256-byte arena through its end. It repeats those comparisons over 160 header
and heap-control mutations and verifies that the arena is unchanged; both the
native assembly and portable builds pass
(`build/i386-heap-query-differential-native.log`,
`build/i386-heap-query-differential-source.log`). This covers a bounded set of
heap layouts and mutations, not all possible heaps.

A fresh paused startup profile of the query-specialized image recorded 1,036
samples; in root-header loading it attributed 169 to `I386HeapScan`, 113 to
`I386HeapScanSelect`, and 101 to `I386HeapFree`
(`build/i386-heap-query-current-profile`). Samples locate remaining work but
are not call counts or an elapsed-time benchmark. Full heap validation remains
a leading startup cost; the 60-second gate and C1–C5 remain open.

Call-stack samples in the same root-header profile put 66 of the
`I386HeapScan` samples under compiler-control validation from token, parser
allocation, intermediate-code allocation and parser-free paths. Publication's
individual record frees account for another 25 `I386HeapFree` samples. These
are nonexclusive statistical observations from this particular run, not call
counts. Any batching or validation reuse must preserve complete corruption
checking, allocation-boundary ownership and interrupt exclusion.

## Parser token ownership search (2026-11-01)

A profile of the shared-call-descriptor image found 88 of 294 root-header
samples in `I386HeapScan`, 60 in `I386HeapScanSelect`, 49 in `I386HeapFree`,
and 26 in `I386ParserToken` (`build/i386-shared-calls-boot-profile`). These
are statistical samples collected while another build was running, not call
counts or a timing comparison.

`I386ParserToken` previously searched its parser-allocation queue after every
lexer call to find a lookahead already registered by a recursive directive.
The control now keeps a saturating token epoch. A non-reentrant lexer call
without an external callback can reuse its pending slot without the second
search. Recursive token calls and all include/directive callbacks advance the
epoch, causing the original complete search. At saturation the full search is
always used. The synchronous callback wrapper refreshes handler pointers after
each callback so a callback can change subsequent handlers. Compiler services
advance to version 77.

A new compiler probe exercises a non-recursive directive that publishes a
parser-owned token, then verifies single ownership and exact cleanup. Another
changes the include handler during a callback and verifies the next include is
rejected and cleaned up. Both run in both native diagnostic phases. An
optional temporary ownership audit checked each skipped search against a full
queue walk; the refined audited image passed the 16 MiB diagnostic
(`build/i386-token-refresh-audit-diag16`). The production image, with the audit
switch off, passed both original rebuild generations, the cross-build and 386
instruction audit, the full 16 MiB diagnostic, and a native nested DolDoc AOT
include fixture (`build/i386-token-refresh-rebuild.log`,
`build/i386-token-refresh-cross`, `build/i386-token-refresh-diag16`,
`build/i386-token-refresh-include-aot`). These checks do not prove every
possible callback or every epoch-saturation state.

A direct conditional fixture attempt timed out while typing its long setup
command, before testing a conditional (`build/i386-token-refresh-conditionals`);
it is not counted as a pass or a compiler failure. The audited earlier variant
also passed nested include and include-error cleanup fixtures, but those runs
preceded the final callback-handler refresh change.

With the retained build and its launcher paused, isolated 8 MiB candidate and
control runs each completed all nine functional checks, exact VGA restoration,
and unchanged disk checks. The candidate took 69.009 seconds and the control
70.641 seconds (`build/i386-token-refresh-pair.json`). Both miss the 60-second
gate. This single pair shows a modest improvement on this host, not a
performance distribution or completion of the timing requirement. The retained
build was resumed afterward and continues on its earlier version-76 image; it
does not test this change. C1–C5 remain open.

## Packaged conditional fixtures (2026-11-01)

The conditional test tools can now stage their exact source files in a
disposable image and handle the welcome screen. This avoids the long typed
setup that timed out above; the original interactive staging remains available.
The packaged 8 MiB JIT fixture passed on both the version-77 candidate and
the earlier control, including nested conditionals, a deliberate invalid
directive, recovery, and the check that the bad definition was not published
(`build/i386-token-conditional-packaged` and
`build/i386-token-conditional-control`). Both runs checked the staged source
and original image bytes.

The packaged AOT fixture also passed on the candidate: its JIT branch returned
98, and its guest-built module returned 99 when loaded by the separate loader
test (`build/i386-token-conditional-aot-packaged-v2`). The loader audit now
accepts `inc`, a valid 386 instruction emitted in that test; the corrected
loader run passed 41 cases. These focused checks do not qualify the full native
build or the startup timing gate. The retained build continues on its pinned
version-76 image, and C1–C5 remain open.

## Parser allocation validation reuse (2026-11-05)

The public-break runtime's paused 8 MiB TCG/486 startup profile collected 399
PC samples (`build/i386-public-break-boot-profile-v1` in the public-break
frontier checkout). Root-header loading accounts for 270 samples, including
84 in `I386HeapScan`, 68 in `I386HeapFree`, and 50 in
`I386HeapScanSelect`. Sixteen root-header stack samples place the query scan
under `CmpControlValid`, `CmpCodeOwner`, and `ParserAlloc`. These are
statistical observations, not call counts or elapsed-time measurements.

`I386ParserAlloc` now retains the complete heap validation performed by
`I386CmpCodeOwner` across its payload and tracking-record allocations. The
outer IRQ exclusion remains held throughout; there are no external callbacks
between validation and these mutations. Physical-block walks select the same
first fitting payload block and last fitting record block. Both public heap
allocators still validate the complete heap before mutation. They and the
parser share the block-splitting, accounting, and zeroing implementation in
`HeapAllocateBlock.HC`. Exhaustion falls back to the public path for its
existing failure diagnostics. Code-provider allocation, parser freeing, and
validation across callbacks are unchanged. No interface or layout changes.

In the parser-heap-reuse checkout, both original bootstrap generations pass
(`build-parser-heap-rebuild-v1.log`), as do the cross-build and 386 instruction
audit (`build/i386-parser-heap-reuse-cross-v1`). The native high-placement
regression passes with assembly and portable validators; the native core heap
regression also passes (`build/i386-heap-high-test`,
`build/i386-heap-high-source-test`, `build/i386-heap-core-test`). High-placement
coverage includes later-header corruption rejection, zeroing, exact payload
sizes, fragmentation recovery, and tiny-prefix absorption. The delivered
source audit matches all 1,366 packaged source/doc files
(`build/i386-parser-heap-reuse-source-audit-v1.json`). The 16 MiB TCG/486 diagnostic also passes both phases, including both parser
memory probes, 54 input cases, and exact comparison of all 307,200 welcome
pixels (`build/i386-parser-heap-reuse-diagnostic-v1/verification.json`).
Normal-image interactive compiler checks subsequently pass as recorded below;
startup qualification and C1–C5 remain open.

The first high-placement launcher attempt preceded completion of the bootstrap
manifest and stopped with `FileNotFoundError`, before compilation or guest
execution (`build-parser-heap-high-v1.log`). The subsequent `v2` launcher run
passed; the failed attempt is retained separately.

The committed candidate's normal 8 MiB TCG `486,-fpu` smoke passes arithmetic,
public structure sizes, and exact VGA with live WinMgr
(`build/i386-parser-heap-reuse-nofpu-v1`). Its startup is 89.027938 seconds;
`build/i386-parser-heap-reuse-startup-budget-v1.json` correctly fails the
unchanged 60-second limit. Other guest suites were running concurrently, so
this run does not establish an isolated performance improvement or regression.
A controlled timing comparison remains pending. The source audit was repeated
against commit `fd95ddda` and still matches all 1,366 delivered files
(`build/i386-parser-heap-reuse-committed-source-audit-v1.json`).

The normal 8 MiB TCG/486 math/compiler regression completes all 149 commands
with exact VGA checkpoints and an unchanged source disk
(`build/i386-parser-heap-reuse-startup-v1/result.json`). It includes the
independent public symbol/storage/literal pointer oracle and source-module help
publication/build checks. Startup is 89.032848 seconds; this concurrent run is
not an isolated performance comparison and does not qualify the 60-second
budget. It used CPU `486`, separately from the explicit no-FPU smoke above.

## Nine-module native build terminal result (2026-11-06)

The retained nine-module run in
build/i386-parser-heap-reuse-v1/build/i386-parser-heap-native-nine-v1 is terminal
and failed in the first module, ConsoleRuntime. Its 64 MiB KVM 486,-fpu guest
rejects inline `DEC ECX` in NativeCallArgs at
Kernel/I386/CallExtStrRuntime.HC:15. No later module was reached. The terminal
source audit in build/i386-parser-heap-native-nine-terminal-audit.json confirms
all 2129 pinned source/tool inputs and the source disk are unchanged.

The native frontend has separate top-level and inline assembly paths. The
former supports DEC; the inline dispatch in FrontendStatements.HC does not.
NativeCallArgs also needs memory PUSH, scaled indexed addressing and indirect
register CALL, so merely replacing DEC in the source would not establish native
self-hosting. The inline compiler must implement and independently exercise
those actual instruction forms before rerunning the full nine-module build.
This failure supplies a compiler frontier, not C5 completion or a timing result.


The subsequent inline-assembler change now implements the actual DEC, indexed
memory PUSH and indirect CALL forms used by NativeCallArgs. The unchanged helper
passes native execution and opcode checks in build/i386-inline-call-native-v1;
the prior image reproduces DEC rejection. See docs/i386-inline-asm.md. A fresh
nine-module attempt is running in build/i386-inline-call-native-nine-v2 with
paced keyboard input after the older harness left its command unsubmitted.
This is a new build attempt, not qualification or a performance result.

## Guarded instruction-slab retirement (2026-11-26)

The candidate reused the compiler's validated code owner during instruction-slab
retirement while interrupts remained disabled. The cross-build source audit
identified only `Compiler/I386/Code.HC` as different. The candidate passed the
task-symbol ownership suite with a fresh bootstrap.

In one paired 8 MiB KVM run on `486,-fpu`, the control reached interactive
startup in 64.877 seconds and the candidate in 64.520 seconds. Both matched
exact VGA at each of the nine command checkpoints. The 0.357-second difference
in a single pair is insufficient to establish a speedup, and both runs exceeded
the 60-second startup limit. The candidate was set aside. The patch, comparison
driver, and result are retained in `build/i386-ic-slab-validation-v1/`.
The separate 16 MiB TCG candidate run subsequently passed the diagnostic
suite and all nine VGA checkpoints. It reached interactive startup in 376.885
seconds and released the worker after its full 1 MiB arena high-water mark.
See `diagnostic16-guarded/result.json` in the same evidence directory.

The frozen 128 MiB retained native-module run had reached EditorRuntime, the
seventh of nine modules, at this checkpoint. Its terminal export audit is still
pending. The run is recorded under `build/i386-demo-insetip-v1/retained128/`.
C1 through C5 remain open.

The frozen `5303f095` run subsequently built and persisted all nine retained
modules at 128 MiB under KVM with `486,-fpu`. The audit matched the cross-build
export sets with the harness's two allowed CompilerRuntime division-boundary
symbols, checked the ConsoleRuntime allocation wrappers, and verified one
BuildRuntime provider load. The receipt records the native and cross-build
module hashes. The generation runner verified the retained image and receipt
hashes and proceeded to the first native install. Two-generation boot and
resource qualification remain pending.

The first install preserved all nine native modules byte for byte and passed
the 8 MiB boot smoke test. Both arithmetic and document allocation matched the
VGA checkpoints, and the document diagnostic loaded, recovered from a growth
failure, and unloaded. Startup took 71.404 seconds. The boot log also records
an emitter allocation rejection in `C:/Adam/Gr/SpriteToCodeCore.HC`, so this
smoke result leaves that startup source path and the 60-second budget open.
The generation run proceeded to the first self-hosted rebuild. Receipts and
the boot trace are in `build/i386-demo-insetip-v1/generations128/gen1-install/`.

## 8 MiB diagnostic worker with a 768 KiB arena

The smaller reservation let the worker start and reach the phase-one public
memory probe. The probe's 131,000-byte zeroed allocation required a 0x1FFB8-byte
backing request and raised an unhandled `OutMem` before the compiler probe
provider was loaded. This profile still needs to reduce overlapping backing
allocations. The experiment preserves the full probe and leaves the production
reservation at 1 MiB. The patch and terminal receipt are in
`build/i386-diagnostic-worker-768k-v1/`.

Generation one subsequently rebuilt and installed its flat kernel using the
guest compiler. Its 8 MiB boot passed both VGA checkpoints in the arithmetic
and document-allocation smoke test. Startup took 72.179 seconds and again
logged the sprite source allocation rejection. The artifact audit passed for
the boot code, 16 modules, and reachable filesystem extents. The delivered
source audit matched 1,578 files to frozen revision `5303f095`. Generation two
has begun rebuilding the retained modules from that guest-built image.

The 512 KiB low-memory worker alternative failed before task creation. The low
arena had 0x86C00 bytes in total, but 0x7EA00 bytes were already in use and its
largest remaining block was 0x81F0 bytes. The worker required 0x85507 bytes
including its stack and task metadata. A solution must account for the
existing low-memory users as well as the main-arena peak. The patch and
terminal receipt are in `build/i386-diagnostic-worker-low-v1/`.

The 640 KiB main-arena trial started the worker and passed its phase-one public
memory probe, including the allocation that exhausted the 768 KiB trial.
Compiler provider loading then failed: its 0x7F500-byte request exceeded the
main arena's largest free block of 0x26FF0 bytes. The loader reclaimed its
scratch allocations. The patch and terminal receipt are in
`build/i386-diagnostic-worker-640k-v1/`. This establishes a separate peak at
provider load while the worker's private heap is still reserved.

The 256 KiB trial again passed the phase-one public memory probe. The provider
loader then failed to allocate its 0x8BF3F-byte source file in the worker's
private heap, before trying the linked image in the main arena. Together with
the 640 KiB trial, this shows that resizing alone cannot accommodate the
current loader's two allocations. The patch and receipt are in
`build/i386-diagnostic-worker-256k-v1/`.

Using the existing in-place loader, the 192 KiB worker passed the public
memory probe and loaded the compiler provider. The private arena then ran out
of space on a 72-byte request after the phase-one native packer probe. This
locates the next failure inside the compiler workload after provider load.
See `build/i386-diagnostic-worker-compact-v1/failure.json`.

The 224 KiB trial also loaded the provider in place. It exhausted the worker
on the same 72-byte request after the native packer marker, with only 48
contiguous bytes free. The next probe compiles the native bundle, and the
extra 32 KiB did not carry the worker through that step. The patch and
terminal receipt are in `build/i386-diagnostic-worker-compact224-v1/`.

The 16 MiB diagnostic measured the worker's native bundle probe separately
from the suite's deliberate exhaustion tests. The private arena went from
5,984 bytes in use before the bundle to 394,048 bytes at peak, including
the existing allocations. The full diagnostic and all nine VGA checks
passed. See `build/i386-diagnostic-bundle-peak-v1/` for the measurement and
test receipt.

Deferring both root header transactions let the 448 KiB worker and its
in-place provider load coexist at 8 MiB. The worker completed the conditional
pressure cases and stopped before the resident-header marker. The next check,
`ProbeResidents`, requires inherited function declarations for `SysTry`,
`SysUntry`, and `throw`. The trial establishes that deferring both header
transactions breaks that dependency. See
`build/i386-diagnostic-worker-defer-headers-v1/`.

Generation two built all nine retained modules from the first self-hosted
image at 128 MiB on KVM with `486,-fpu`. The persisted export audit passed
and the build provider loaded once. The retained image hash matches the
receipt in `build/i386-demo-insetip-v1/generations128/gen2-retained-build/`.
The runner has started installing the second generation.

The second retained install preserved all nine modules and passed its 8 MiB
arithmetic and document-allocation VGA checkpoints, including diagnostic
growth recovery. Startup took 71.983 seconds and still logged the sprite
source allocation rejection. The runner advanced to the second flat-kernel
rebuild. See `build/i386-demo-insetip-v1/generations128/gen2-install/`.

Deferring only root user headers let the 448 KiB worker pass the inherited
resident-header checks, the native bundle, and the native loader at 8 MiB.
The bundle used 400,888 bytes at peak. The subsequent probe exhausted emitter
space in `ModuleCheck.HC`, so the worker did not reach user header publication
or the interactive checks. See
`build/i386-diagnostic-worker-defer-user-v1/failure.json`.

The frozen two-generation rebuild, install, boot, delivered-source, and
artifact audits passed. The identity audit compared 16 modules and allowed
only the exported eight-byte kernel build date to differ within its artifact
scope. It verified each actual boot payload, checksum, and padding before
comparison. The second self-hosted image passed both 8 MiB VGA smoke
checkpoints and reached interactive startup in 72.231 seconds. It still logged
the sprite source allocation rejection. The full desktop and application
suite and the 60-second startup budget remain open. See
`build/i386-demo-insetip-v1/generations128/`.

The 640 KiB worker passed the full 8 MiB TCG diagnostic and all nine VGA
checkpoints with `486,-fpu`. Kernel declarations were published before the
worker, and user headers loaded after it released its allocation. The provider
loaded in place in the main arena. The console service version is 276 because
its header callback now selects the publication phase. Diagnostic startup
took 427.445 seconds. The separate 60-second interactive budget is still
open. See `build/i386-diagnostic-worker-defer-user640-v1/diagnostic8/result.json`.

The corresponding normal 8 MiB image passed all nine VGA checkpoints under
KVM with `486,-fpu` and live WinMgr. It reached interactive startup in 63.584
seconds, above the 60-second gate. Its boot trace has no
`SpriteToCodeCore.HC` allocation rejection. See
`build/i386-diagnostic-worker-defer-user640-v1/interactive8-kvm/budget.json`.

The same version-276 image also passed the full 16 MiB TCG diagnostic
regression on `486,-fpu`, including all nine exact VGA checks. See
`build/i386-diagnostic-worker-defer-user640-v1/diagnostic16/result.json`.

The normal version-276 image passed the delivered-source audit for all
1,578 packaged source and documentation files against the committed
diagnostic fix at `ba76aa5c`. The audit found no source differences.
See `build/i386-diagnostic-worker-defer-user640-v1/committed-source-audit.json`.

The normal version-276 image produced 1,394 PC samples under the paused TCG
profiler. During startup source compilation, 52 samples were in heap
validation under instruction allocation and 51 were in heap validation under
instruction-slab release. The latter runs through `I386COCInstructionsRelease`.
These are statistical samples. The independent KVM run measured elapsed
startup time. See
`build/i386-diagnostic-worker-defer-user640-v1/interactive8-profile-retry/result.json`.

A bounded instruction-slab release trial validated the control and heap
once per batch of up to 16 slots. The task-symbol ownership test and 386
boot audit passed. In the paired 8 MiB KVM run, both images passed all nine
VGA checkpoints. The control took 64.561 seconds and the candidate took
63.420 seconds. The earlier control run took 63.584 seconds, so this pair
does not establish a repeatable speedup. Both exceeded the 60-second gate.
The candidate remains a patch while its full diagnostic runs. See
`build/i386-ic-release-batch-v2/`.

The bounded instruction-release candidate also passed the full 8 MiB
diagnostic and all nine VGA checkpoints. Its measured startup comparison
still leaves the 60-second gate open. The diagnostic receipt is in
`build/i386-ic-release-batch-v2/diagnostic8/result.json`.

The loader overflow trial reused the indexed prefix and scanned only the
unindexed suffix for saturated buckets. Its 16-bit bucket heads kept the
emitted stack audit to 15,984 of 16,384 bytes. The assembly and portable
index builders both passed the 40-case loader suite. In one 8 MiB KVM pair,
the control took 63.255 seconds and the candidate took 62.902 seconds.
Both passed all nine exact VGA checkpoints. This pair does not establish
a repeatable speedup, and the candidate is retained as a patch while the
60-second gate remains open. See `build/i386-loader-overflow-tail-v3/`.

Both frozen self-hosted images passed the nine-command 64 MiB KVM desktop
baseline with the managed pointer and Window Manager active. Generation one
also matched all 686 inventoried files and passed the bounded guest read
fixture. Generation two passed the same inventory and guest read checks.
The complete desktop and application workflow suite remains open.
See `build/i386-demo-insetip-v1/generations128/`.

The configured 64 MiB HomeSys workflow passed on frozen generation one.
It selected `/Home/Once.HC`, matched all 83 reference window geometry fields,
retired the bootstrap task, verified that its former address was in a free
heap block, and evaluated `6*7` in the new desktop. The handoff took 223.128
seconds in this configured test. Generation two passed the same handoff
and reaping checks in 223.827 seconds and produced a byte-identical
geometry capture. See the `gen1-desktop64` and `gen2-desktop64` receipts in
`build/i386-demo-insetip-v1/generations128/`.

The first self-hosted image passed the 8 MiB managed-welcome resource
profile. Twenty document development cycles peaked at 37,840 live bytes,
7,824 bytes above baseline, with 55,808 bytes reserved. All 11 VGA
checkpoints matched and the source disk hash was unchanged. The second
generation passed with identical heap measurements and VGA results. See
the `gen1-resource8` and `gen2-resource8` receipts in
`build/i386-demo-insetip-v1/generations128/`.

### Startup after the assembly demo ports

The MulByHand full image reached interactive startup in 63.198 and
63.403 seconds in two isolated 8 MiB KVM boots with `486,-fpu`, the
managed pointer and the Window Manager active. Both runs passed all
nine exact VGA checkpoints and preserved the source image. The second
run used the startup test's new `--accel kvm` option, with TCG still
the default. Both timings exceed the 60-second target.
[First timing receipt](../build/i386-mul-by-hand-port-v1/interactive8-kvm/budget.json) ·
[Repeat timing receipt](../build/i386-mul-by-hand-port-v1/interactive8-kvm-repeat/result.json)

The paused KVM profile of the same image collected 709 samples. ATA
transfer accounted for 192 of 236 foundation samples, including 184
stacks through the bounded RedSea loader. During kernel and user header
publication, it accounted for 34 of 48 and 66 of 170 samples respectively.
The most frequent header transfer stack went through RedSea directory
lookup. Startup source had 70 heap scan samples and 67 ATA transfer
samples out of 251. These are sampled PCs from a paused guest. The two
unpaused runs above supply the elapsed times. An initial TCG profile
timed out at 260 seconds during startup source and retained its partial
samples locally.
[Verified KVM sample summary](../build/i386-mul-by-hand-port-v1/startup-profile8-kvm/summary.json)

### ATA word transfers during startup

The boot and task-owned ATA paths receive each 256-word data phase with
`REP INSW`. The PIO command, per-sector scratch buffer, final status
check, and publication of validated read bytes retain their existing
order. The native assembler emits the same 386 instruction when the
guest compiles the helper. Both bootstrap generations, the cross-image
instruction audit, the native encoding fixture, RedSea module loading,
and the ATA ownership/poisoned-channel suite passed.

Two isolated 8 MiB KVM boots reached the prompt in 31.505 and 31.504
seconds with nine exact VGA checkpoints and the Window Manager active,
compared with the preceding image's 63.198 and 63.403 seconds. The TCG
attempt timed out before the startup source completed, so the 60-second
TCG reference gate remains open. The standalone ATA corpus stopped at
write-flush case 55 on both the candidate and the unchanged `c0227921`
control. Both had passed the preceding identify, LBA and CHS read checks.
[First KVM boot](../build/i386-ata-string-read-v1/interactive8-kvm/result.json) ·
[Repeat KVM boot](../build/i386-ata-string-read-v1/interactive8-kvm-repeat/result.json) ·
[TCG attempt](../build/i386-ata-string-read-v1/interactive8-tcg/result.json)

The ATA candidate also passed the full 8 MiB diagnostic boot under KVM
in 47.099 seconds. It completed 128 immediate-push checks, 22 declaration
publication checks, and 28 program publication checks. Both memory-probe
phases and all nine exact VGA checkpoints passed, with zero BuildRuntime
loads and the source image unchanged.
[8 MiB diagnostic receipt](../build/i386-ata-string-read-v1/diagnostic8-kvm/result.json)

The paused TCG profile of the ATA candidate completed and collected 2,307
samples. The three heap walks `I386HeapScan`, `I386HeapScanSelect`, and
`I386HeapFree` account for 564 of 761 user-header samples and 953 of
1,300 startup-source samples. The path through `I386CmpControlValid` and
`I386CmpCodeOwner` accounts for 141 and 291 of the `I386HeapScan` samples
in those phases. In the foundation phase, symbol lookup and module
validation account for 109 of 141 samples. These samples identify the
remaining TCG work after the ATA change. Pausing the guest makes the
profile unsuitable for judging elapsed startup time.
[Verified TCG sample summary](../build/i386-ata-string-read-v1/startup-profile8-tcg/summary.json)

An isolated unpaused TCG run used `--startup-timeout 380` on the same image.
It reached the prompt in 291.886 seconds and passed all nine VGA checks
with the managed pointer and Window Manager active. The observation
limit allowed a complete measurement. The runner rejected the result
against the unchanged 60-second target and verified the input hashes.
[Completed reference timing receipt](../build/i386-ata-string-read-v1/interactive8-tcg-extended/result.json)

### Bounded instruction release under TCG

The earlier 16-slot release batch was rebuilt on the ATA word-input
candidate. The two images differed in one OS source, `Compiler/I386/Code.HC`.
Among the modules, CompilerRuntime changed and the Kernel changed only
within its build date field. Both bootstrap generations, the 386 boot
audit, and the task-symbol ownership corpus passed.

The trial reached the 8 MiB TCG prompt in 270.106 seconds and passed all
nine exact VGA checkpoints. The separately measured control took 291.886
seconds. Both exceed the 60-second gate. The source batch remains an
experimental patch pending repeat timing on this profile.
[Timing comparison](../build/i386-ic-release-tcg-v1/comparison.json) ·
[Task-symbol ownership receipt](../build/i386-ic-release-tcg-v1/task-symbols/result.json)

### Reuse compiler ownership validation for code allocations

The instruction slab, standalone instruction, miscellaneous record, and
saved code header allocation paths now use the existing validated-arena
selector. Each call follows `I386CmpCodeOwner` in the same IRQ-disabled
section. They preserve first-fit placement, zeroing policy, and the
public allocator's exhaustion reporting. The heap mutation helper is
shared with parser allocations and has an include guard for test modules
that compile both callers together.

Both bootstrap generations, the boot audit, task-symbol ownership,
compiler-control cleanup, and the 8 MiB full KVM diagnostics passed.
The isolated 8 MiB TCG run passed nine exact VGA checkpoints and reached
the prompt in 269.148 seconds. The earlier ATA control took 291.886
seconds. The runs were measured separately, and the 60-second TCG gate
remains open.
[TCG timing](../build/i386-code-alloc-known-v1/interactive8-tcg/result.json) ·
[KVM diagnostics](../build/i386-code-alloc-known-v1/diagnostic8-kvm/result.json)

Parser adoption also reuses the arena validation done by
`I386CmpCodeOwner` while IRQs remain excluded. It still checks that
the supplied pointer starts a live allocation with at least one
requested byte before attaching its ownership record. Both bootstrap
generations, the 386 boot audit, the task-symbol ownership corpus,
and the 8 MiB KVM diagnostics passed. The diagnostics matched all
nine VGA checkpoints.
[Task-symbol ownership](../build/i386-parser-take-known-v1/task-symbols/result.json) ·
[8 MiB diagnostics](../build/i386-parser-take-known-v1/diagnostic8-kvm/result.json)

The parser-adoption image matched all 1,578 delivered source and
documentation files to revision `d02fb3d2`. Its 64 MiB KVM content
check verified all 686 inventory files and passed the bounded guest
lookup and read workflow.
[Delivered-source audit](../build/i386-parser-take-known-v1/committed-source-audit.json) ·
[Full content](../build/i386-parser-take-known-v1/full-content64/result.json)

The parser-adoption image reached the 8 MiB TCG prompt in 275.026
seconds with all nine VGA checkpoints exact. The preceding assembler
image measured 278.656 seconds. The retained rebuild was active
during both runs, and the profiling guest also overlapped part of
each run. The difference is a single observation and both runs
exceeded the 60-second gate.
[Parser-adoption TCG timing](../build/i386-parser-take-known-v1/interactive8-tcg/result.json)

The paused TCG profile of the preceding assembler image collected 2,916
samples. The three heap walks accounted for 709 of 976 root-header
samples and 1,179 of 1,641 startup-source samples. The control validation
path through `I386CmpCodeOwner` accounted for 159 and 395 samples,
respectively. These are sampling counts. The unpaused run records the
startup time separately.
[TCG profile summary](../build/i386-optimization-port-v1/startup-profile8-tcg/summary.json) ·
[Unpaused startup receipt](../build/i386-optimization-port-v1/interactive8-tcg/result.json)

The full image with the code-allocation change matched all 686 inventory
files against the working tree and passed the bounded guest content
workflow under KVM at 64 MiB. The volume audit covered 1,949 files and
matched the allocation bitmap to reachable extents.
[Full-content receipt](../build/i386-code-alloc-known-v1/full-content64/result.json)

The guest rebuilt CompilerRuntime from the same image at 128 MiB under
KVM. The emitted 1,360,717-byte module passed the export audit and was
the only added file. The source image contained 1,151 kernel and compiler
files matching committed revision `84d1c25f` and the cross-build pins.

The installer replaced CompilerRuntime with those exact guest-built
bytes. A separate 8 MiB KVM cold boot passed the allocation check and
rendered fresh arithmetic. Installation changed only the module and its
build-output path. The allocation check added its expected `AllocRead.DD`
fixture, and the volume audit verified the reachable extents at each step.
[Native build](../build/i386-code-alloc-known-v1/native-compiler128/result.json) ·
[Install and cold boot](../build/i386-code-alloc-known-v1/native-compiler-install/result.json) ·
[Source and disk audit](../build/i386-code-alloc-known-v1/native-compiler128/provenance.json)

With the guest-built CompilerRuntime installed, the 64 MiB KVM desktop
baseline passed all nine exact VGA checks with the managed pointer and
Window Manager active. The 8 MiB document resource profile passed all
20 cycles and 11 VGA checkpoints. Peak live use was 37,840 bytes,
7,824 above baseline, and peak reservation was 55,808 bytes. Both
tests preserved the installed source image.
[Desktop baseline](../build/i386-code-alloc-known-v1/native-compiler-desktop64/result.json) ·
[Document resource receipt](../build/i386-code-alloc-known-v1/native-compiler-resource8/resource-result.json)

The image with guest-built CompilerRuntime also passed three 64 MiB KVM
checks. Configured HomeSys selected the Home Once file, matched all 83
original geometry values, reclaimed the bootstrap task, and returned
fresh arithmetic. Its geometry capture is byte-identical to the previous
frozen generation's capture. The persistent graphics trial passed the
red, green, blue, and cleared frames and returned to exact prompt input
using its disposable plain-start fixture. The five bundled assembly
demos also matched their original DolDoc output byte for byte.
[Configured HomeSys](../build/i386-code-alloc-known-v1/native-compiler-homesys64/result.json) ·
[Persistent composition](../build/i386-code-alloc-known-v1/native-compiler-composition64/result.json) ·
[Bundled assembly comparison](../build/i386-code-alloc-known-v1/native-compiler-demos64/result.json)

On the same installed-compiler image, the original-body editor accepted
Save and both autosave toggles, saved the exact text and cursor position,
and reopened the file after cold boot. TimeClock reproduced the original
5,400-second report and exact VGA frames after reboot. Budget completed
its original-reference template and periodic-copy workflows under
`/Home` and reopened the saved data without changing files or metadata.
All three tests used 64 MiB KVM guests and preserved the source image.
[Editor save and reopen](../build/i386-code-alloc-known-v1/native-compiler-edit-save64/result.json) ·
[TimeClock report](../build/i386-code-alloc-known-v1/native-compiler-timeclock64/result.json) ·
[Budget templates](../build/i386-code-alloc-known-v1/native-compiler-budget64/result.json)

The installed native compiler also passed all 24 public assembly
records, with one publication of each compiler service and fresh
arithmetic. RegistryDemo ran for three boots on the same base image.
It incremented the value to 1236 and verified the saved score on the
third boot. The only file changes were the configured Home registry
and the three capture files. Both tests preserved their source image.
[Public assembly](../build/i386-code-alloc-known-v1/native-compiler-public-assembly64/result.json) ·
[RegistryDemo three-boot receipt](../build/i386-code-alloc-known-v1/native-compiler-registry64/result.json)

## 8 MiB profile with the task report available

The full task-report image collected 2,748 paused TCG samples. The three
whole-arena heap walks accounted for 700 of 960 root-header samples and
1,033 of 1,491 startup-source samples. In the startup-source phase, 369
samples in `I386HeapScan` traced through `I386CmpCodeOwner` and 105
through `I386ICSlabFind` during code release. These paths account for
distinct work. The PC counts attribute time spent in sampled code without
measuring the 60-second startup gate.
[Verified sample summary](../build/i386-task-report-v2/startup-profile8-tcg/summary.json)

The unpaused TCG gate run for the same image stopped at an `OutMem` rejection
while compiling `C:/Adam/Gr/SpriteToCodeCore.HC`. The 8 MiB KVM resource
check and paused TCG profile also logged that rejection and subsequently
reached the prompt. The strict run returned no valid startup time.
[Timed run receipt](../build/i386-task-report-v2/interactive8-tcg/result.json) ·
[Startup trace](../build/i386-task-report-v2/interactive8-tcg/debug.log)

Compiler node retirement now reuses the arena validation already done by
`I386CmpCodeOwner` while interrupts remain excluded. It still checks physical
allocation boundaries, the registered slab and its exact allocation size,
and the node lifetime record. Other lookup and teardown callers retain the
full arena validation. The original two-generation bootstrap, 386 boot audit,
task-symbol and compiler ownership corpus, and full 8 MiB KVM diagnostics passed.
[Ownership corpus](../build/i386-ic-lifetime-known-v4/task-symbols/result.json) ·
[8 MiB diagnostics](../build/i386-ic-lifetime-known-v4/diagnostic8-kvm/result.json)

Moving the sprite helper load ahead of autocomplete, task settings, and
directory diagnostics avoided the 8 MiB startup rejection on the task-report
image. The source-only disk trial reached the managed prompt in 32.388 seconds
under KVM, passed the nine normal VGA checkpoints, and confirmed that
`Sprite2Code` was published. A trial that split the sprite converter into a
second Adam compilation still exhausted the heap.
[Strict KVM trial](../build/i386-sprite-startup-early-v1/result.json)

The integrated full image cross-built from clean revision `5786a5ce` with
both the compiler retirement change and the sprite load order. Its strict
8 MiB KVM run reached the managed prompt in 32.346 seconds and passed all
nine exact VGA checkpoints. The startup trace had no allocation rejection
or build-provider load.
[Integrated KVM startup](../build/i386-sprite-early-integrated-v1/interactive8-kvm/result.json) ·
[386 boot audit](../build/i386-sprite-early-integrated-v1/cross/boot-instruction-audit.json)

The source-only sprite load-order trial also reached the prompt under
8 MiB TCG in 279.356 seconds. All nine normal VGA checkpoints and the
`Sprite2Code` publication check passed, with no allocation rejection.
The run exceeded the 60-second startup limit.
[Strict TCG trial](../build/i386-sprite-startup-early-v1/result-tcg.json)

On the same integrated build, the full 8 MiB KVM diagnostics passed all
nine exact VGA checkpoints, 128 immediate-push checks, 22 publication
checks, and 28 program-publication checks. The delivered-source audit
matched all 1,581 packaged source and documentation files to revision
`5786a5ce`.
[Integrated diagnostics](../build/i386-sprite-early-integrated-v1/diagnostic8-kvm/result.json) ·
[Delivered-source audit](../build/i386-sprite-early-integrated-v1/committed-source-audit.json)

The integrated image also passed the 64 MiB full-content check. It
matched all 686 inventory files, verified the RedSea extents, and passed
the bounded guest lookup and read contract.
[Integrated full-content check](../build/i386-sprite-early-integrated-v1/full-content64/result.json)

An 8 MiB normal KVM boot of the integrated image also executed
`Sprite2Code`. It serialized a transform-on element as the exact
`Transform{ON};` line followed by the DolDoc terminator, and the prompt
displayed fresh arithmetic after the fixture allocations were released.
[Sprite conversion check](../build/i386-sprite-early-integrated-v1/sprite-conversion8-capture/result.json)

Parser allocation size queries now reuse the whole-arena audit performed
by control validation under IRQ exclusion. The lookup walks physical block
boundaries and returns the live block's requested byte count. The exact-size
and minimum-size predicates reject a missing block before comparing against
their unsigned size arguments. The task-symbol corpus passed its interior
pointer and corrupted-metadata checks. The original bootstrap, 386 boot
audit, and full 8 MiB KVM diagnostics also passed.
[Ownership corpus](../build/i386-parser-known-request-v2/task-symbols/result.json) ·
[8 MiB diagnostics](../build/i386-parser-known-request-v2/diagnostic8-kvm/result.json)

The exact-size parser lookup candidate reached the 8 MiB prompt under TCG
in 290.367 seconds and passed all nine VGA checkpoints without an allocation
rejection. The preceding integrated image took 293.352 seconds in a separate
run. The timing observations were made with other guest activity on the host,
and the 60-second gate remains open.
[Parser lookup timing](../build/i386-parser-known-request-v2/interactive8-tcg/result.json) ·
[Startup budget result](../build/i386-parser-known-request-v2/interactive8-tcg/startup-budget.json)

The normal 8 MiB KVM boots with the sprite load-order fix and with the
later GrPeek binding both reached the prompt, then reported `OutMem` on
the initial include of `DocSessionResourceCheck.HC`. Neither ran the
20 document sessions. The GrPeek trace shows a 128-byte allocation
request with a largest free payload of 120 bytes.
[Integrated resource failure](../build/i386-sprite-early-integrated-v1/resource8/out-of-memory.json) ·
[GrPeek resource failure](../build/i386-gr-peek-public-v1/resource8/out-of-memory.json)

A stopped KVM heap capture on the GrPeek image found 93,016 bytes of
free payload across 221 blocks before the document-session include. The
largest was 18,440 bytes. At failure, the 128-byte request came from
`I386ICAddBytes` through `I386ParserHeapAllocKnown`, and the heap had
only 120 bytes in its largest block. After the rejected input returned,
the largest block recovered to 18,440 bytes. The arena retained 5,760
additional live bytes and 65 allocations compared with the earlier
capture. The snapshots do not establish whether those allocations
are still needed.
[Main-arena snapshots](../build/i386-resource-oom-heap-v1/result.json)

A hardware breakpoint captured the main arena at the 128-byte request,
before exception cleanup. It had 5,216 free payload bytes across 149
blocks and a largest free payload of 120 bytes. The failing control's
18 IR slabs were linked and full. Every slot had a matching ownership
record. Changing the preferred slab size alone could not recover
unissued or freed slots from this capture.
[Heap at allocation failure](../build/i386-resource-oom-at-failure-v3/result.json)

The same failure capture shows 1,552 free payload bytes in the low-memory
fallback heap, with a largest free payload of 496 bytes. The public backing
pool had 14,336 bytes free across 40 regions. Every region contained live
allocations, so whole-region trimming could return no region to the main
arena at the breakpoint.
[Fallback heap and backing-pool census](../build/i386-resource-oom-at-failure-v3/backing-census.json)

The resource runner now accepts a 16 MiB comparison profile while
retaining its default 8 MiB release profile and checking the selected RAM
in both the QEMU invocation and receipt. At 16 MiB the same GrPeek disk
that rejected the 8 MiB include completed every document session and
matched all eleven VGA checkpoints. Live document heap use peaked at
38,080 bytes, 7,824 above baseline. This isolates the 8 MiB failure from
the document session behavior that follows successful compilation.
[16 MiB comparison](../build/i386-resource-oom-reference16-v2/resource-result.json)

At 16 MiB, snapshots before and after compiling the same document fixture
on the GrPeek disk show the main arena high-water mark rising from
6,706,136 to 6,759,408 bytes. This was 108,632 bytes above the precompile
live use and 12,272 bytes beyond the 8 MiB arena's entire capacity.
Allocation placement can differ across profiles. This establishes the
observed successful footprint, while the 8 MiB breakpoint independently
shows fragmentation and exhaustion.
[Successful compile heap comparison](../build/i386-resource-oom-reference16-v1/compile-heap-comparison.json)
