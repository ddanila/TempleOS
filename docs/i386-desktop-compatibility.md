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

Each entry records the original Git blob and SHA-256, literal includes, public
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

## Milestone status

| Milestone | State | Next evidence |
| --- | --- | --- |
| C1 | In progress | Reviewed program/feature/API matrix with original observations and executable oracles |
| C2 | Existing 64 MiB baseline passes | Firmware RAM discovery/capacity tests, then original desktop workflows |
| C3 | Pending | App-by-app failing tests and equivalent port behavior |
| C4 | Pending | Mapped API and document differential coverage |
| C5 | Pending | Complete suite on two native generations and measured resource profiles |
