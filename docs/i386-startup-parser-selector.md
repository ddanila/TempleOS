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

## Reuse validation for parser tracking-record allocation

Two additional allocation sites can reuse existing whole-arena validation
without changing `I386CmpControlValid` or `I386CmpCodeOwner`:

- `I386ParserCodeAlloc` allocates its tracking record after CodeOwner and task
  heap-owner checks, before invoking the executable-storage callback.
- `I386ParserTake` allocates its tracking record after CodeOwner, the public
  payload-size query and duplicate-adoption check.

Both retain IRQ exclusion throughout those checks and the record allocation.
Neither invokes a callback or mutates the heap between validation and selection.
They now use the same known-valid last-fit selector as ordinary parser storage.
The selected record remains zeroed with its exact original requested size.
Executable allocation/release callbacks, adoption ownership, failure rollback
and the public allocator's exhaustion fallback remain unchanged. In particular,
no validity cache survives a callback, yield or return to the caller.

Fresh verification is under `parser-record-select-build-v1` and
`parser-record-select-regressions-v1`. Both classic self-rebuilds, the full cross
build and complete386 instruction audit pass. All1869 source and26 helper pins
were copied and independently hash-checked under the cross run's
`pinned-candidate` before further edits. User8MiB, original Home paths,
diagnostics16MiB in both phases and configured Home Once/normal desktop geometry,
bootstrap physical reclamation and fresh42 all pass. These focused checks do not
qualify the complete desktop/application suite or native generations.

The current full disk SHA256 is
05d89c7b400e31dd551de47e94e6c4838c6d86004ac8696e58089d7234ae27fc;
CompilerRuntime SHA256 is
8d9ccb7d9fef480a6f2cefac18856e18cccc242b87fe402990a11e51a23b20c6.
The stock isolated minimal startup test completes all nine unchanged commands
and exact managed-pointer framebuffer checks, with zero startup build-provider
loads. Startup measures165.7311s, so the unchanged60s gate correctly fails.
All timing inputs were independently rehashed after the run. Receipt SHA256:
8463f7702ca7e4ebe6c3e0c57752a6eb20c6e69aa90c78c68c6b977251533556.
This single observation is not a paired performance comparison with169.4702s;
no precise speedup is claimed. The aggregate regression receipt stays failed.

`parser-record-select-regressions-v1/functional-audit.json` separately verifies
current and archived source/helper pins, all16 emitted modules, flat kernel,
disk and the four focused runtime receipts. Its explicit startup_budget_pass
is FALSE. This change does not address the dominant control-validation scan
itself. Full C1-C5 and current-source native-generation qualification remain
open; compatibility inventory remains2/686.

## Saved-header validation investigation

The private saved-header validator and detached-chain walker now explicitly
name their known-valid-arena precondition. Their only entry paths are pop,
header-free and append, each after `I386CmpCodeOwner` under continuous IRQ
exclusion. They invoke no callbacks and mutate no heap metadata during lookup.
The initial complete arena audit stays unchanged; subsequent header lookups
use `I386HeapKnownSize`, which walks actual physical block boundaries before
checking the exact requested size. Header control/kind/allocation identity and
the bounded detached-chain/cycle checks remain unchanged. Append still invokes
the independently validated public header-free boundary after joining graphs.

`ProbeCodeHeaderBoundaries` adds12 rejection checks per diagnostic phase:
pop/free/append against a forged owned header inside a real payload, and the
same three entry points against a real earlier header with later-block reserved
corruption, inconsistent used bytes or inconsistent allocation count. The fake
includes a plausible heap prefix and matching control/kind/allocation fields,
so an unchecked ptr-16 size lookup cannot satisfy the probe. It also requires
the original saved-stack pointer, final arena accounting, complete heap validity
and IRQ exclusion to survive, then reclaims all temporary resources. Existing
unwind diagnostics retain positive save/push/pop/append/free coverage.

The first cross run (`code-header-known-build-v1`) rejects the newly used high
allocator at its strict import-contract check after both classic rebuilds and
module emission succeed. The check is explicitly extended for that probe-only
import and now requires the boundary-probe export. The separate program probe
retains its exact prior import contract. Both emitted module contracts pass the
updated checker; mutating the boundary export name is confirmed to be rejected.
The failed v1 build and dependent queues are retained, not counted as runtime
success. The v2 build passes, along with User and Home-path checks, but diagnostic
loading correctly rejects the missing guest-side high-allocator binding. That
binding is now explicit in the diagnostic loader; the program loader is unchanged.
A v3 cross attempt requires fresh classic source pins after this bare-kernel edit
and is retained as failed. Fresh classic/cross/runtime evidence is pending under
`code-header-known-build-v4` and `code-header-known-regressions-v4`. A separate
queued reference run will test the new probes against the prior ABI105
CompilerRuntime after timing has ended.

The v4 fresh classic rebuilds, full cross build and complete386 audit now pass.
Its1869 source and26 helper files are archived and independently hash-checked
under `i386-code-header-known-cross-v4/pinned-candidate`. User8MiB, original
Home paths, diagnostics16MiB and configured Home Once/normal desktop geometry/
bootstrap physical reclamation/fresh42 pass. Both diagnostic phases execute
the new boundary probe and existing program probes, followed by document
load/growth-recovery/unload. The stock isolated minimal-content8MiB TCG test
completes all nine unchanged commands and exact managed-pointer frames with
zero startup build-provider loads. Startup measures162.2253s and correctly
fails the unchanged60s target. Its inputs were independently rehashed after
completion. Receipt SHA256:
83a235bcfd96d0612e9a64fc9f74226907048376cb8465d7b3e6da818f9bd903.
This is a single observation, not a paired speedup estimate. The aggregate
receipt stays failed; the scoped functional audit explicitly records
startup_budget_pass FALSE.
C1-C5, current-source native generations and inventory2/686 remain open.

Full disk SHA256:
ab83883ad4ec2b8e5eb3c47f78cd0732ddcf083b7e00d10557a33ae720085593.
CompilerRuntime SHA256:
faec49d6c49c29d3cc4129e180d376564920e4ca35322e7062a643066913fa79.

The prior-runtime comparison now passes in `code-header-known-reference-v4`.
The same new probe executes24 rejection calls across its two diagnostic phases
against the preceding ABI105 CompilerRuntime, followed by program and document
recovery. Every other file was independently compared unchanged in that explicit
replacement image. The two actual diagnostic images were independently decoded
to confirm distinct candidate/prior CompilerRuntime hashes. Both complete guest
logs are byte-identical. This is diagnostic behavioral parity, not qualification
of the mixed reference image as a current-source or native generation.
`code-header-known-regressions-v4/header-boundary-parity-audit.json` retains the
module identities, log hashes and reference receipt hash. Reference receipt:
df4bfb9673ac03dc931c20e4b1c88472e7958812a24df999ba884fed4f9fff3b.

## Emitter validation and allocation reuse

`I386OutValid` now holds IRQ exclusion around the unchanged whole-arena owner
audit and an exact physical-boundary lookup for its output header. This also
covers the backend caller which enters without exclusion. No proof is cached
across exclusion. Contiguous reserve retains its outer exclusion and uses a
known-size lookup for the existing data allocation. Its preceding nonzero
`I386OutCapacity` result establishes the original signed32-bit capacity bounds
before converting that exact expected size to the lookup's U32 argument.

Output headers, contiguous growth buffers and segmented chunks now allocate
through the existing known-valid selector after validation, without intervening
callbacks or arena mutation. The original first-fit policy, exact requested
sizes, zeroing policy and public exhaustion fallback remain unchanged. Old-buffer
and chunk release still use their public validation paths. Segmented reserve
retains its largest-useful-window search and512-byte chunk maximum.

`ProbeEmitterBoundaries` requires six rejection cases per diagnostic phase:
delete a forged output header inside a real payload; delete a real earlier
header while later reserved metadata, used bytes or allocation count is corrupt;
and reserve with capacity -1 or0x100000040. The last value's low32 bits equal
the actual64-byte buffer, guarding against an unchecked narrowing conversion.
The original output bytes/count/data pointer, final heap accounting/validity
and IRQ exclusion must survive. Existing emitter diagnostics retain64 growth/
execution cycles, signed-word vectors, exact-capacity emission, exhaustion,
retry and control-unwind coverage. The strict host contract now requires the
new probe export; its imports already belong to the previous exact contract.

`emitter-known-build-v1` passes both fresh classic self-rebuilds, the full cross
build and complete386 audit. Its1869 source and26 helper files are archived and
hash-checked under `i386-emitter-known-cross-v1/pinned-candidate`. Both exact
probe import contracts pass, and renaming the emitter export is independently
confirmed to fail the strict checker.

`emitter-known-regressions-v1` passes User8MiB, original Home paths and16MiB
diagnostics. Both phases execute the new emitter boundary cases, saved-header
boundary cases, existing emitter stress probes and complete program probes,
followed by document load/growth-recovery/unload. Its
`partial-functional-audit.json` independently checks current/archived pins,
all16 exported and actually delivered modules, flat kernel and disk, plus the
three focused receipts. It explicitly leaves startup_budget_pass null.

Full disk SHA256:
e9960a654ee1359da47f52173da2ba2940f2cc8b8cdd86737d05b95ef99995b6.
CompilerRuntime SHA256:
e218f435cee24526e8dd468a7d361f1fe4134d81e20ebd1e79b76f9495597b29.
The configured desktop run now passes original geometry, Home Once selection,
bootstrap physical reclamation and fresh42. The stock isolated minimal-content
test at8MiB TCG486,-fpu completes all nine unchanged commands and exact managed
pointer frames with zero startup build-provider loads. It measures166.5236s,
then correctly fails the unchanged60s gate. All timing inputs were independently
rehashed after completion. Receipt SHA256:
0a9e9ea97f45378a1c928bb4d45f20e28a5d618f1c50187770d55a3f39a9eae9.
This single observation does not establish a speedup over the prior162.2253s
observation. The aggregate remains failed; `functional-audit.json` includes all
four focused receipts and explicitly records startup_budget_pass FALSE.

`emitter-known-reference-v1` also passes the same12 emitter rejection cases,
existing growth/word/exact-capacity/exhaustion/retry/unwind probes,24 saved-header
rejections and subsequent program/document recovery against the prior ABI105
CompilerRuntime. All other replacement-image files were independently compared
unchanged. The actual candidate and reference diagnostic images were decoded to
verify their distinct CompilerRuntime identities. This is functional parity,
not current-source or native-generation qualification of the mixed reference
image. `emitter-parity-audit.json` retains both module/log identities and the
reference receipt hash:
d330934753382392e5cf109e29c531259bcb888800748c30ce7ba9e088a067e1.
C1-C5, the60s startup gate, current native generations and inventory2/686 remain
open; no release qualification or measured performance gain is claimed.
