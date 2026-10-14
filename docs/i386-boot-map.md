# Versioned firmware RAM map

The extended loader collects E820 records while in real mode before its first
BIOS disk-sector transfer. This supplements the existing 32-byte legacy
handoff without changing that ABI. Collection and allocation selection are
implemented; connection to normal kernel arena initialization remains pending.

The BIOS interface follows the [ACPI system address map specification](https://uefi.org/specs/ACPI/6.5/15_System_Address_Map_Interfaces.html):
use the SMAP signature, carry flag, returned descriptor size and continuation
token. Only type 1 with plain attributes is considered usable by this port.
Other types and attributes remain excluded. Twenty-byte records receive the
ordinary attribute default; 24-byte records retain the returned attributes.

## Handoff layout

`CI386BootMap` is at physical `0x5040`:

| Offset | Field |
| --- | --- |
| 0 | U32 magic `0x50324D49` |
| 4 | U32 version 1 |
| 8 | U32 count, at most 32 |
| 12 | U32 complete, exactly 1 for an accepted enumeration |
| 16 | Up to 32 entries of 24 bytes: U64 base, U64 size, U32 type, U32 attributes |

The fixed reservation ends at `0x5350`, below the `0x6000` disk bounce buffer.
Initialization clears count/completion. Unsupported, malformed or truncated
queries leave completion clear; the kernel must retain its conservative legacy
fallback for such input. Carry after a prior descriptor is accepted as the
specified end-of-enumeration convention. At most 32 records are accepted,
bounding a BIOS that repeats continuation tokens. `BOOT_MAP_FAIL` injects an
unavailable enumeration for testing.

## Selector contract

`I386BootMapArena(info,map,reserved,count,result)` validates the legacy record,
map header, every map range and up to 128 caller reservations before writing
its result. Callers provide stable readable inputs and a separate writable
result. Range overflow, empty records, invalid counts or incomplete maps reject
without changing the result. Selection uses only high memory after A20 has
been verified by the caller; the selector itself never enables A20.

Only type 1 / attributes 1 ranges supply candidates. Every other map range and
all caller reservations subtract from those candidates, so reserved coverage
wins over usable overlaps. The selector also excludes memory below `0x110000`
and the legacy 15–16 MiB device hole. Usable ranges clip below 4 GiB. It selects
the largest eight-byte-aligned gap of at least 24 bytes; equal gaps choose the
lower address. It returns one contiguous arena rather than merging ownership
across gaps. Kernel integration must preserve the live high boot-image
reservation and existing firmware/stack reservations.

## Qualification

```sh
python3 tools/test-i386.py --memory --qmp-stdio
python3 tools/test-i386-boot-map-handoff.py --build CROSS_BUILD \
  --out build/map-handoff-64m
python3 tools/test-i386-boot-map-handoff.py --build CROSS_BUILD \
  --out build/map-unavailable-64m --force-unavailable
```

The memory fixture includes synthetic map selection, overlapping reservations,
unknown types/attributes, malformed headers/ranges and unchanged-output checks,
alongside the existing legacy memory suite. Further cases cover alignment,
4 GiB clipping and unsorted equal gaps. An overlapping-reservation test exposed
and corrected a signed/unsigned loop-bound error before kernel integration.
The native instruction audit remains part of that test.

The loader test assembles current stage code around an unchanged prior kernel,
checks payload identity, audits executable loader ranges for the 386 ISA and
reads the handoff through the interactive prompt on `486,-fpu` at 64 MiB.
Its scope is BIOS transport, not new-kernel allocator capacity. Normal handoff
passes in `build/i386-c1-map-handoff-64m`. The expanded selector suite passes
with both legacy BIOS variants in `build/i386-memory-test/result.json`; the
forced-unavailable handoff also passes in
`build/i386-c1-map-unavailable-64m/result.json`, with unchanged inputs.

Next: connect the selector to kernel arena initialization after A20 verification,
then rerun the failing 32/80 MiB capacity tests and existing minimal profiles.
Neither the larger usable-memory profiles nor C1–C5 are yet qualified.

## Kernel integration and allocation policy qualification

The kernel now tries the validated map after A20 verification, preserving its
live boot-image/stack reservations and reporting either `BOOT MAP selected` or
`BOOT MAP legacy`. Bootstrap and cross-build/386 audits pass. The first
integrated image passes 32 MiB allocation/readback at 64 MiB, but its 128 MiB
profile rejects an 80 MiB request: page bucket rounding requests a 128 MiB
backing extent, larger than the selected 112 MiB arena. This failure is preserved
in `build/i386-c1-map-capacity-128m`.

A focused 300-page pool regression reproduces the policy failure with a
280-page request (failure code 157, `build/i386-c1-large-pages-red.log`). The
implementation keeps ordinary bucket rounding, then retries the original page
count only after rounded allocation, merge and growth fail. Non-bucket-sized
returned blocks use the general free-extent list; bucket shapes remain intact.
The fixture checks reuse, accounting, aligned payload capacity, endpoint data
and full teardown. It passes with the revised allocator. This pressure policy
is an intentional allocation-policy difference to review in C4; public payload
and ownership contracts remain required.

The updated bootstrap and cross-build pass. Current qualification is running
sequentially in `build/i386-c1-map-qualification`: 80/32 MiB allocation/readback,
8 MiB retained-state/VGA startup, 16 MiB saved assembly/native builds, integrated
legacy fallback, public/core/portable-cache heap tests and backing accounting.
These checks remain pending until their results are terminal. Full desktop
compatibility and complete native rebuilding at 128 MiB are separate open gates.

The revised candidate now passes both capacity tests: 80 MiB at 128 MiB and
32 MiB at 64 MiB, including page/endpoint readback, release and subsequent
arithmetic. Evidence is under `build/i386-c1-map-qualification/capacity-128m`
and `capacity-64m`; source inputs remain unchanged. The queue has advanced to
the existing 8 MiB startup gate. Remaining qualification stages are still open.

## Integrated foundation regressions pass (2026-10-14)

All planned integration checks now pass. The original queue preserves its
public-heap failure in `build/i386-c1-map-qualification/result.json`: its old
fixture required a request to fail when only bucket rounding prevented it from
fitting. The revised fixture explicitly verifies exact-page success, private
buffer preservation, full reclamation and ordinary rounding when space returns.
That public-heap rerun and all remaining heap regressions pass in
`build/i386-c1-map-remaining/result.json`. No guest allocator change was needed
for this fixture correction.

Together the two reports cover 32/80 MiB capacity/readback, the unchanged 8 MiB
startup/VGA gate, native saved assembly at 16 MiB, integrated legacy fallback,
public/core/portable-cache heaps and backing accounting. Bootstrap and 386
instruction audits also pass. These establish the memory foundation for desktop
work; complete application coverage and native rebuilding at 128 MiB remain open.
