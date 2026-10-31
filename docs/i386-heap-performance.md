# Native bootstrap heap validation cost

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
