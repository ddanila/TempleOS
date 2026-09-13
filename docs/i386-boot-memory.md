# Initial BIOS memory handoff

The protected-mode test boot path now collects a fixed-width record at physical
0x5000 before loading the stage and entering protected mode. `BootMemory.HH`
defines the matching HolyC layout; all fields are U32 and the record is 32 bytes.

| Offset | Field | Meaning |
| --- | --- | --- |
| 0 | magic | `0x4D323349` (`I32M`) |
| 4 | version | 1 |
| 8 | conventional_kib | INT 12h result in KiB |
| 12 | extended_kib | INT 15h/AH=88h result, or zero on failure |
| 16 | ebda_base | Physical address from the BDA segment pointer at 0x40E; zero if absent |
| 20 | stage_begin | 0x10000 |
| 24 | stage_end | Exclusive end of the full BIOS-loaded stage reservation |
| 28 | flags | Bit 0: conventional result present; bit 1: extended query succeeded |

The boot stub clears the extended-memory result before the query and preserves
its unavailable state on carry-set failure. No E801, E820, ACPI, PCI, or protected-
mode BIOS call is needed. The legacy query reports a quantity, not a complete
map of usable memory. For emulator behavior, see SeaBIOS's
[legacy memory query](https://github.com/coreboot/seabios/blob/master/src/system.c)
and [BIOS data area layout](https://github.com/coreboot/seabios/blob/master/src/std/bda.h).

## Arena selection

`I386BootArena(info, reserved, count, result)` chooses the largest eight-byte-aligned
conventional-memory gap, with at least 24 bytes for the arena allocator. Equal
candidates choose the lower address. The selector validates the record and all
reservation ranges before writing its result; failure leaves the result unchanged.
Inputs must be readable, stable caller-owned records, and the result must be a
separate writable record.

Everything below `stage_end` is reserved, including IVT/BDA, the handoff, the
real-mode boot stack, and the entire loaded stage. The upper bound is the smaller
of conventional memory and a nonzero EBDA base, and can never exceed 0xA0000.
Thus VGA memory, adapter/firmware space, and all extended memory stay excluded.
Caller reservations are subtracted as a union, including overlapping and unsorted
ranges. Up to 128 ranges are supported; empty ranges and wrapping endpoints are
rejected. A high reservation ending exactly at 4 GiB is valid but cannot enlarge
the conventional-memory candidate.

VGA and native loader tests reserve 0x70000–0x8FFFF for their packet scratch space
and protected-mode stack, then initialize a heap from the selected gap. They no
longer choose a fixed heap base/size. The other heap stress fixtures retain their
separate deliberately fixed arenas for guard-byte testing.

## Verification and limits

`python3 tools/test-i386.py --memory` compiles the selector into native i386 code.
Its fixture checks the real BIOS handoff and synthetic cases for EBDA limits,
reservation unions, alignment, equal gaps, insufficient space, invalid records,
invalid counts, endpoint overflow, and unchanged outputs after rejection. The
reported extended-memory quantity must not expand the selected arena.

The test runs both the normal BIOS query and an injected carry-set failure. The
normal QEMU 8 MiB profile must report a positive quantity no greater than
7168 KiB; the inspected BIOS reported 7040 KiB. The test does not assume all
installed memory is available. The failure variant must report no extended-memory
result. Both execute the same
instruction-audited selector. The injection exercises the error branch after the
BIOS call; it does not establish behavior on a physically absent BIOS service.

The test stub currently requires 576–640 KiB of conventional memory and rejects
an EBDA below 0x90000, because the test runner stack is still fixed there. This is
not the final OS boot contract. The selector itself can handle lower conventional
limits when given suitable reservations; it does not relocate a running stack.

A20 enabling/verification, extended-memory hole handling and usable-range
selection, a production boot image, task/page-pool integration, and actual 386
machine profiles remain pending. The current use of conventional RAM is an
intermediate bring-up step, not a substitute for the full 8–16 MiB OS target.
