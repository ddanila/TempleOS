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
