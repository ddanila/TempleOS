# Native bootstrap heap validation cost

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
