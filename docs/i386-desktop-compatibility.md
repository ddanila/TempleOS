# Original desktop and application compatibility

The C1–C5 goal is defined near the top of [PLAN.md](../PLAN.md). This document
tracks the reference inventory and qualification work without treating previous
focused port tests as full original-application coverage.

## Pinned reference and discovery

Use original snapshot `c26482bb6ad3f80106d28504ec5db3c6a360732c`, the same
immutable original snapshot used by `tools/build-iso.py`. Its complete tree is
listed in [the machine-readable inventory](i386-compatibility-inventory.json):
686 blobs, including 73 application files and 224 demo files. The inventory
retains boot files, root startup scripts, supporting services, documents and
assets as well as source files. Nothing in that reference tree is silently
excluded from review.

The effective reference also pins binary-repair commit
`ce055f205fc38536443289fb1cfc73632f6624f4`, described in
[binary repair provenance](binary-repairs.md). The raw archive has 44 damaged
map/asset blobs; restoring it alone reproduces the historical `Bin Not Found`
startup loop. The inventory retains both archive and recovered blob IDs and
uses the recovered bytes for reference SHA-256 and source comparison. The
original 686-file scope is unchanged; repair-commit tooling additions are excluded.
A guard rejects removal or substitution of this repair revision.

Each entry records archive/recovered Git blobs and the effective SHA-256, literal includes, public
symbol candidates, initial source comparison, and explicit compatibility,
workflow, oracle and test fields. Launch and symbol candidates are lexical
hints; dynamic includes, macros, assembly entry points and runtime dependencies
need review. All 686 entries currently remain unqualified. Shared assets may
later be qualified through the workflows that consume them, with that evidence
recorded explicitly. The inventory is discovery progress, not C1 completion.

```sh
python3 tools/inventory-i386-compatibility.py --check
python3 tools/test-i386-compatibility-inventory.py
python3 tools/inventory-i386-compatibility.py --check --require-qualified
```

The final command currently fails intentionally. Coverage checks reject a
missing reference file or changed reference digest. To regenerate discovery,
write to a fresh `--output` path, review the differences, and preserve reviewed
workflow/test fields when updating the checked-in inventory. `source_at_discovery`
is an initial observation, not a live runtime status.

## C1 remaining work

Review launch candidates and group helper files/assets under their consuming
programs. The reference has twelve application directories: Budget, GrModels,
KeepAway, Logic, Psalmody, Span, Strut, TimeClock, Titanium, ToTheFront,
Vocabulary and X-Caliber. Run/Load names identify entry candidates; TimeClock
uses Load.HC rather than Run.HC. Inspect their actual installation and startup
behavior before defining launch commands.

For every application/demo and desktop feature, record a representative
workflow, dependencies, original-system observation and independent executable
oracle. Public services need a declaration/API review beyond the lexical symbol
hints. Existing focused tests are useful candidates for evidence, but must be
mapped and requalified at the required scope. No original application is yet
claimed compatible by this inventory.

The [application launch review](i386-application-matrix.md) records source-verified
entry points and direct Load dependencies for all twelve application directories,
plus the first persistent-data reference-capture workflows. Runtime observations
and executable per-program oracles remain open.

## Runnable baseline and memory profiles

The input harness now accepts 8, 16, 64 and 128 MiB, through both its Python API
and `--ram-mib` CLI argument. The new baseline test runs the existing nine
retained-state/graphics/VGA commands on a disposable writable copy, checks that
normal boot does not load build-only support, and preserves input hashes.
It records startup time without assigning the minimal profile's 60-second gate
to the larger desktop profile.

```sh
python3 tools/test-i386-desktop-baseline.py IMAGE \
  --out build/desktop-baseline-64m --ram-mib 64
```

The initial test failed before guest launch because the harness rejected 64 MiB
(`build/i386-c1-desktop-64m-red/result.json`). This establishes the harness gap
before adding the new profiles. The 64 MiB run on the previously qualified
second-generation image passes all nine commands and exact VGA checkpoints,
with zero build-provider loads and unchanged inputs. Evidence:
`build/i386-c1-desktop-64m/result.json`. Startup took
54.31 seconds on the recorded host.
The same nine-command baseline also passes at 128 MiB with exact VGA,
zero build-provider loads and preserved inputs; startup took 54.22 seconds
(`build/i386-c1-desktop-128m/result.json`).
This checks the existing interactive environment; full desktop/application
qualification and access to all advertised RAM require separate evidence.

## Discovered RAM capacity gap

The larger QEMU setting does not yet make all that memory usable. The existing
boot arena deliberately caps its high end at `0xF00000` (15 MiB), below the
legacy device hole, in `Kernel/I386/BootMemory.HC`. The 64 MiB baseline log
reports base `0x188000`, size `0xD78000`, ending at that limit. Its pass therefore
proves behavior with a larger emulated machine, not a 64 MiB allocator.

Before larger desktop workloads, add a failing capacity test and implement
firmware-described RAM discovery/reservation across the legacy hole. Preserve
the existing 8/16 MiB profiles, live boot-image and firmware reservations, A20
validation and ownership accounting. Qualify usable capacity independently of
the QEMU `-m` argument; 128 MiB native rebuilding cannot be claimed until this
gap is closed and rebuilding is tested.

## Capacity regression: expected failure (2026-10-14)

`tools/test-i386-desktop-capacity.py` requires a 32 MiB public allocation at
64 MiB RAM (80 MiB at 128 MiB), touches each 4 KiB and the final byte, verifies
readback after returning to the prompt, releases it, and checks subsequent
arithmetic. It runs on a writable copy and records preserved-input hashes.

```sh
python3 tools/test-i386-desktop-capacity.py IMAGE \
  --out build/desktop-capacity-64m --ram-mib 64
```

The first 64 MiB run fails at `MAlloc(33554432)` with OutMem, observed on VGA
and in the guest exception log. Its boot arena is `0x188000 + 0xD78000`, ending
at the legacy 15 MiB cap. Inputs remain unchanged. Evidence:
`build/i386-c1-capacity-64m-red/result.json` and its `qemu/debug.log`.
The allocation check is a required failing regression, not a passing test or
an accepted reduction of the larger-memory goal.

The implementation should retain the legacy handoff for existing fixtures,
add a separately versioned firmware RAM map, and select/own usable RAM only
after validating map bounds, types, attributes, overflow and reservations.
The map must not consume live boot buffers or the BIOS transfer buffer. Map
entries may be unsorted, overlapping or unavailable: test those cases, prefer
reserved coverage over usable overlaps, and retain a conservative legacy
fallback. Keep firmware/device holes excluded, verify A20 before high-memory
use and prove outputs unchanged on invalid input. Only claim 64/128 MiB usable
profiles after allocation readback, reserved-hole rejection and minimal-profile
regressions pass on the resulting image.

## Firmware-map implementation checkpoint (2026-10-14)

The [versioned RAM-map handoff and selector](i386-boot-map.md) are implemented
without changing the legacy ABI. The initial native selector suite passes and
caught a reservation-loop signedness defect during development. Expanded
alignment/boundary cases and the forced-unavailable transport test also pass.
The normal BIOS transport test passes using the unchanged prior kernel;
loader executable ranges pass the 386 instruction audit. This is foundation
work: the normal kernel still uses the legacy capped arena until integration
and capacity/minimal-profile regressions are complete.

## Milestone status

| Milestone | State | Next evidence |
| --- | --- | --- |
| C1 | In progress | Reviewed program/feature/API matrix with original observations and executable oracles |
| C2 | Existing 64 MiB baseline passes | Firmware RAM discovery/capacity tests, then original desktop workflows |
| C3 | Pending | App-by-app failing tests and equivalent port behavior |
| C4 | Pending | Mapped API and document differential coverage |
| C5 | Pending | Complete suite on two native generations and measured resource profiles |

## Integrated memory checkpoint under qualification

The map is now connected to kernel initialization. Bootstrap/cross-build pass,
and 32 MiB allocation/readback succeeds at 64 MiB. The first 80 MiB allocation
at 128 MiB exposed excessive page-bucket rounding; a focused failing regression
and pressure fallback fix are recorded in the [memory-map contract](i386-boot-map.md).
The fixed candidate's capacity, minimal-profile, fallback and heap-accounting
queue is live in `build/i386-c1-map-qualification`. No full desktop or 128 MiB
native-rebuild qualification follows from these foundation tests.

Both corrected capacity tests pass (32 MiB at 64 MiB, 80 MiB at 128 MiB).
The queue has advanced to minimal-profile startup; assembly, fallback and heap
regressions remain pending. Larger-profile native rebuilding is still open.

The integrated memory foundation regressions now pass. The first queue's old
public-heap failure is preserved; the revised policy-aware test and remaining
heap checks pass in `build/i386-c1-map-remaining/result.json`. See the memory-map
contract for the test correction and exact coverage. TimeClock original storage
and report reference capture is the next C1 experiment.

## First original application component oracle (2026-10-14)

TimeClock original Load/Install, typed storage, reopen and closed report now
have an executable reference capture. The fixture restores all original source
and binaries with the pinned recovered assets, then creates two controlled
entries on a disposable RAM drive. Host checks independently assemble the
34-byte logical record stream and calculate the 5,400-second interval, then
compare the complete report with the reviewed capture in
`tests/i386/timeclock-reference.json`. The three TimeClock source entries now
link this original-only evidence in the inventory; compatibility remains
unqualified. Interactive PunchIn/PunchOut, cancellation, reboot persistence,
native execution and native/original differential comparison remain open.

```sh
python3 tools/test-i386-timeclock-reference.py --out build/timeclock-reference
```

Evidence: `build/i386-c1-timeclock-reference-final/result.json`. The earlier raw
archive failure is preserved in `build/i386-c1-timeclock-reference`; it exposed
the reference-provenance issue rather than a native application regression.

## First native application load test (2026-10-14)

The additive application packager places all three unchanged TimeClock files
on a new native image while preserving the original tree, metadata and boot
area. Host tests cover binary/empty files, idempotence, source preservation and
six conflict/path/payload rejection cases. Guest lookup now finds Load.HC;
the actual original Load script fails at `__DIR__`. A focused stream-block test
also fails at KW_EXE, before formatting or injection. The shared parser exists,
but native execution/include hooks and public stream services remain missing.
See [compile-time stream compatibility](i386-compile-stream.md) for exact tests
and the implementation/ownership boundaries. TimeClock remains unqualified.

```sh
python3 tools/package-i386-application.py IMAGE --app TimeClock --out build/timeclock-package
python3 tools/test-i386-application-package.py IMAGE
python3 tools/test-i386-timeclock-native.py build/timeclock-package/candidate.img --out build/timeclock-load
python3 tools/test-i386-stream-block.py IMAGE --out build/stream-block
```

The final two commands currently fail intentionally, identifying work to port.
Packaging itself passes (`build/i386-c1-timeclock-package-pinned/result.json`);
its image is byte-identical to the application load test input.

## Stream execution and next TimeClock dependency

The first native compile-time stream implementation passes its eight-command
64 MiB test and the existing 8 MiB startup/VGA gate (41.90 seconds). TimeClock's
unchanged Load script gets past __DIR__ and now rejects Now at TimeClk.HC line
88. NativeNow exists but lacks public exposure. The expanded directory-context
fixture passes all seventeen commands, persisted bytes and exact VGA; complete stream cleanup/AOT and native application storage,
report and interactive workflows remain open. See the stream contract for
exact source, runtime and test limitations.

## Public clock binding qualified (2026-10-14)

Console interface version 68 now exposes existing NativeNow as public Now.
The failing public-API baseline is preserved; all nine revised clock commands
pass at 64 MiB with exact VGA and preserved inputs. Bootstrap/cross-build/386
audits pass, and the existing 8 MiB startup gate also passes. See
[calendar and clock qualification](i386-date-conversion.md) for the scope and
remaining RTC-mode/precision coverage. TimeClock source loading now advances
to GetStr at TimeClk.HC line 127. Native storage/report and interactive/reboot
workflows remain open; the original application sources are unchanged.
