# Minimal startup profiling and parser selection candidate

The default-Home production epoch passes its focused functional checks, but
isolated TCG486,-fpu/8MiB minimal startup does not complete before180 seconds.
The existing60-second target remains a release gate, not an optional target.

`build/default-home-minimal-boot-profile-v1/profile/result.json` records837
paused PC/stack samples and unchanged input disk. These are statistical hints,
not elapsed-time benchmarks or call counts. Of434 root-header samples,126 are
in I386ParserHeapAllocKnown and217 in the checked heap scan/free/select paths.
Startup-source samples are also dominated by heap operations. No declarations,
validation, workloads or instruction requirements are removed to address this.

## First candidate: preserve first/last-fit, compact the known-valid traversal

I386ParserAlloc already validates the owner and complete heap while IRQ exclusion
is retained. Its only two calls to I386ParserHeapAllocKnown allocate payload and
tracking record; the intervening allocator mutation preserves heap invariants.
The candidate replaces only that private C traversal with equivalent386 assembly.
It preserves physical first/last-fit addresses, size/overflow checks, zeroing,
allocation/failure handling and every public validation boundary. The selected
block still goes through the unchanged HeapAllocateBlock implementation.

The standalone fixture checks14 explicit cases plus512 fragmented layouts,
33 sizes and both directions:33806 selection assertions per validator. It
compares against the existing C traversal and checks the entire arena/control
bytes and IF state after each query. Exhausted heaps, large no-fit requests,
a later insufficient free block, coalescence and noncanonical true2 are included.
Both assembly and portable heap validators pass. See
`build/parser-heap-select-prototype-v1/verification.json` for verified inputs and
both raw receipts. The initial20s runner observation timeout is preserved;
the exact same binary passes with180s allowance and the full corpus unchanged.
The stock backing-mode labels in that early borrowed harness are not backing
coverage; the separate verification receipt scopes the actual selector checks.

A dedicated versioned `--heap-parser-select SELECTOR` mode and fixtures were
checked after the isolated timing pair ended. It reports its
own selector assertion count, not unrelated public/backing case counts.

`parser-select-compiler-cross-v1` cross-builds the candidate CompilerRuntime.
`parser-select-runtime-queue-v1` passes complete386 instruction audit, functional
guest provider replacement and independent8MiB welcome/42/DocAllocationCheck13.
The module is explicitly cross-built, not native-built. Source overrides and
all baseline source hashes are recorded. The source delta is preserved as
`docs/patches/i386-parser-selector-prototype.patch`; production integration is being verified separately.

## Timing and pointer-oracle boundary

The first extended observation run reaches the prompt, then fails the legacy
no-pointer framebuffer expectation. Its actual frame exactly matches all307200
pixels of the existing independent standard-pointer oracle, including the
permitted blinking caret. The mismatch to the old expectation is17 pointer
pixels, not an arithmetic or text failure. Exact comparison proof is retained
in `parser-select-isolated-pair-v1/before/pointer-oracle-audit.json`.

The startup-memory tool gains an opt-in managed-pointer check that forwards to
that existing exact oracle. It does not change the guest, the nine commands,
startup observation timeout180s or60s budget. The active v2 paired experiment
uses that oracle, identical boot areas and otherwise preserved minimal files,
with sequential isolated before/candidate runs. Its900s observation allowance
is diagnostic so the known-red startup can be measured; it does not replace
the stock acceptance gate. Performance benefit and60s acceptance are unproven
until their respective results complete. Full C1-C5 remain open2/686.

## Paired result and complete candidate checks

The corrected isolated comparison completes
(`build/parser-select-isolated-pair-v2/result.json`). Before startup is206.3296s;
candidate startup is161.9011s:21.53% lower in this pair. Both run the unchanged
nine-command minimal workload, with exact standard-pointer frames throughout.
The candidate's explicit candidate_startup_budget_pass is FALSE. The experiment
receipt passing means the comparison and functional checks completed, not that
the60-second gate passed. Its inputs and boot areas remain unchanged.

The dedicated versioned mode now passes both validators under
`build/parser-select-mode-regressions-v1`, independently reporting33806 selector
assertions, exact selector/fixture input hashes and no unrelated public/backing
coverage. Reproduce with fresh output directories:

```sh
python3 tools/test-i386.py --heap --heap-parser-select tests/guest/i386-heap/ParserHeapSelectCandidate.HC --qmp-stdio --out build/select-asm-NEW
python3 tools/test-i386.py --heap --heap-parser-select tests/guest/i386-heap/ParserHeapSelectCandidate.HC --heap-source --qmp-stdio --out build/select-source-NEW
```

`parser-select-diagnostic-queue-v1` also passes16MiB candidate diagnostics:
both parser packing/memory/program phases, allocation/failure/unwind vectors and
document load/growth recovery/unload. This is a cross-provider candidate, not a
native generation. The measured improvement is applied locally for fresh
production classic/cross, functional and timing checks. Those current-source
gates are pending. No release or complete C1-C5 qualification is claimed.

## Production integration verified, budget still failed

`build/i386-parser-selector-cross-v1` now contains the integrated source. Its
CompilerRuntime is byte-identical to the measured prototype:1245618 bytes,
SHA256 eab38625adb0521f0ef56def4b37822de4bf3e8f873caebe9c9f0333515d1c33.
Fresh original rebuild, full cross build and complete386 audit pass.
`parser-selector-production-regressions-v1/functional-audit.json` independently
checks1869 source pins,26 helper pins, all16 modules, flat/disk identity and
passing User8MiB, original home paths, diagnostics16MiB and configured normal
HOME Once/desktop/physical reaping. Source/helper files are archived under that
cross run's pinned-candidate before further edits.

The stock startup-memory runner, using its new opt-in exact managed-pointer
oracle, completes all nine unchanged workload commands and exact frames. It
measures169.4702s on the independently packaged16MiB minimal-content image at
8MiB TCG486,-fpu. The runner then correctly fails its unchanged60-second target;
its180-second observation limit also stays unchanged. Receipt SHA256:
88cc00bd2f7bf9d095990e2711976e426228bdce72e3b98874d7d869b2de1e8a.
No input changed during the run. The aggregate production regression receipt
remains failed and is not reclassified by the focused functional audit.

The production full image SHA256 is
52314aa5e1263724b5ca59dd69bd7973d470b998bd196b2091775d1f5d0a7a6b.
This is an intermediate performance improvement with functional verification,
not startup/release/C1-C5 qualification. A further paused production profile is
queued only after the isolated run has ended, to identify the remaining costs.

## Production profile attribution

The queued production profile completed with659 samples and both successful
startup markers. Its retained disk is unchanged. This paused run is statistical
attribution, not timing or startup-budget acceptance. Reproduce the checked
comparison from raw samples with:

```sh
python3 tools/summarize-i386-boot-profile.py build/default-home-minimal-boot-profile-v1/profile build/parser-selector-production-profile-v1/profile
```

The summarizer reconstructs every phase/symbol and complete captured-stack
counter and requires exact agreement with each profiler report. It also requires
successful startup markers and the recorded unchanged-disk check. Input hashes
are retained in `build/parser-selector-production-profile-v1/comparison.json`.
An inconsistent sample-count report was independently confirmed to be rejected.

Root-header samples fell from434 to313; startup-source samples from279 to234.
These counts must not be interpreted as elapsed-time ratios. The new selector
occupies5 root-header and1 startup-source samples. Remaining root-header costs
include96 HeapScan,64 HeapFree and54 HeapScanSelect samples. Of the96 HeapScan
samples,67 have the immediate HeapSize / CmpControlValid / CmpCodeOwner caller
chain. That chain also accounts for47 of102 startup-source HeapScan samples.
Thus repeated compiler-control validation is the next concrete investigation,
alongside free/selection scans; the parser selector itself is no longer the
dominant sampled loop.

`I386CmpCodeOwner` currently establishes full arena validity through
`I386CmpControlValid`, then uses boundary-checked known-size lookup for the task
scope under IRQ exclusion. Replacing that initial validation with a cached or
unchecked header test would weaken corruption detection. Any next optimization
must retain whole-arena validation at exposed boundaries, actual block-boundary
checks, and rejection of later-block corruption and inconsistent counters. No
such validation change is included here. The169.4702s timing failure remains.
