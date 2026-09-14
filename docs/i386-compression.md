# Native compression dictionary foundation

`Kernel/Arc.HH` now shares CArcEntry, CArcCtrl, CArcCompress and the compression
constants between architectures. KernelA includes the same declarations. The
archive header stays 17 bytes, with two I64 sizes followed by the compression
byte and body at offset 17. In-memory entry/control layouts depend on pointer
width: entries are 16/12 bytes and controls 98456/65664 bytes on x64/i386.

`Kernel/I386/Arc.HC` supplies I386ArcEntryGet using native pointer arithmetic.
It follows the existing allocator's growth from the initial literal alphabet to
12-bit codes, then selects reusable leaf entries and unlinks their old hash-chain
membership. Pointer-to-pointer chain updates avoid assuming an eight-byte pointer
or sixteen-byte entry. Only bit zero of entry_used is consumed; other bits remain
unchanged, matching the original BTR instruction.

The x64 assembly allocator remains in place. The native routine requires an
exclusively owned, initialized control and valid dictionary chains. It performs
no allocation, I/O or interrupt-state change. It is an internal codec operation,
not validation or expansion of an archive buffer.

## Verification

The dedicated `tools/test-i386.py --arc` fixture first runs the original x64
assembly through its exported entry, then runs the native routine. Each mode
(7-bit and 8-bit literals) performs 20000 dictionary updates. The corpus exercises
width transitions, 12-bit reuse, occupied-slot skipping, hash-chain unlinking and
no-op/active entry_used states with higher bits set. State and normalized pointer
indices feed a hash after each transition; every final hash chain is traversed,
checked and included. The original fd119d3 results are frozen:

| Mode | Trace hash |
| --- | --- |
| 7-bit | C2BBC609CFFE2505 |
| 8-bit | B11B35864A95B67A |

Native runs use a 128 KiB heap arena separate from the 64 KiB fixture loader.
Both allocated controls are reclaimed and the heap must return to its baseline.
The fixture also asserts both architecture layouts, and its generated executable
passes the 386 instruction audit on the QEMU/486 development profile.

Both x64 rebuild/reboot generations and the full native kernel boot suite pass.
The native dictionary code is not yet linked into the standalone bootstrap.
The streaming decoder now has native coverage through the shared loop described
in `docs/i386-arc-expand.md`. Whole-archive validation and ownership, file-service
decompression and include dispatch remain required. This component does not yet let the native OS read .Z
source files or prove complete compression support.

## Owned controls and expansion stacks

`ArcCtrlSeed` shares initialization of a fresh zeroed control. The x64 constructor
still uses its allocator and assembly dictionary setup. Native `I386ArcCtrlNew`
allocates an owned control, optionally allocates the 4096-byte expansion stack,
then seeds and advances the native dictionary. It publishes the pointer only
after all allocations succeed. As in the original constructor, only CT_7_BIT
selects seven-bit literals; other mode values select eight. Archive-type validation
belongs in the whole-buffer expansion service.

The native owner stores the heap and stack allocation outside the public control.
`I386ArcCtrlDel` validates that ownership, releases the constructor-owned stack
and record and leaves source/destination buffers borrowed. It uses the recorded
allocation even if decoder fields such as stk_base/stk_ptr have changed. Wrong
heap, null, foreign raw controls and repeat deletion are rejected. Both functions
preserve the caller's interrupt state around heap operations.

Native heap spans are 65696 bytes for a control and 69808 bytes with an expansion
stack, in one or two allocations respectively. Shared lifecycle checks inspect
fresh fields and zero dictionary storage for twelve mode/stack combinations.
Native cases additionally cover 33 exhausted arenas, exact-fit success, default
arguments, partial-allocation reclamation, ownership rejection, borrowed buffers,
changed decoder pointers and both interrupt states. The streaming decoder now uses these controls, but whole-archive output ownership
and file integration remain open.
