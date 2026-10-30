# Shared archive stream expansion

`Kernel/ArcExpand.HC` contains the original streaming expansion loop. Its callbacks
read the next code and advance dictionary allocation. The x64 ArcExpandBuf uses
the original bit-field reader and assembly dictionary allocator; the native
I386ArcExpandBuf uses byte-based bit extraction and I386ArcEntryGet. Dictionary
hash-chain insertion uses pointer-to-pointer updates, with no fixed pointer stride.

The loop retains the original state model: src_pos/src_size count bits,
dst_pos/dst_size count bytes, and pending decoded bytes remain on the control's
expansion stack. Increasing dst_size permits incremental output; increasing
src_size permits further input after a call stops before the next complete code.
The first code is read through the callback immediately when output is requested.

Native bit extraction touches only bytes containing the requested field and does
not advance src_pos itself. It rejects a field outside the declared input bits.
The native wrapper rejects basic invalid extents, cursor ranges and 32-bit address
wrap before calling the shared loop. No allocation or interrupt manipulation
occurs during expansion. Source, destination and stack remain borrowed from the
caller/control owner; no output terminator is added.

Both APIs are internal codec operations requiring initialized, exclusively owned
state, a valid dictionary/stack and well-formed compressed codes. They do not
validate arbitrary archive contents or protect against every corrupt dictionary
chain. I386ExpandBuf now supplies a checked reader, header validation and owned output
for complete archives; see `docs/i386-expand-buffer.md`. File integration remains
open.

A true result means the loop stopped normally, not that the requested output is
complete: inspect dst_pos. A negative read callback result makes ArcExpandStep
return false and records the number of output bytes already written. The failed
code does not advance src_pos. Other state can already have changed; discard or
reset the control after a reader error rather than treating it as a resumable
transaction.

## Verification

`tools/test-i386.py --arc-expand` uses the original x64 compressor to produce six
fixtures: repeated and random 32768-byte sources plus single-byte input, each in
7-bit and 8-bit modes. Before extraction, both complete and incremental output
passed against the original decoder at dc55f97. The compressor remains unchanged.
Random fixtures produce enough codes to fill and reuse the 12-bit dictionary;
repeated runs exercise the special current-entry case and stack buffering.

Native tests compare every decoded byte with the independently generated input
for complete output, incremental output and input extended after its first code
(18 expansions). They check output canaries, final stack/cursor state and complete
heap reclamation. Forty bit-field cases check unaligned reads and one-bit-short
rejection. Additional cases cover invalid input extents and a callback failure
after the first decoded byte, including interrupt-state preservation.

The fixture embeds its generated vectors in a 256 KiB loader reservation and
uses a separate 128 KiB heap at 0x60000. This changes only the test profile; the
standalone bootstrap reservation and target hardware contract are unchanged.

Validation:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --arc-expand
python3 tools/test-i386.py --arc
python3 tools/build-i386-kernel.py --test
```

The retained Console/Editor native build based on the FIFO candidate failed at
module packing: two function definitions were named `NativeArcBFieldExtU32`
(`build/i386-c5-deduplicate-native-build`). The archive-specific macro had
also renamed the later sprite bit-field definition. The console now includes
one shared `BFieldExtU32` implementation before the archive and sprite code,
without that alias. Both original rebuild generations and the cross-build and
386 audit pass (`build/i386-c5-shared-bitfield-cross`). The native public
FileRead fixture passes all 24 commands, including expanded and alternate `.Z`
reads, with its source disk unchanged (`build/i386-c5-shared-bitfield-file-read`).
Its 59.103013-second startup was concurrent, not an isolated timing gate.

The public bit-field fixture timed out at its first lookup for `BFieldExtU32`,
before running its vectors (`build/i386-c5-shared-bitfield-native`). It does
not qualify the shared function's public availability or behavior. A new
retained Console/Editor build from the corrected image is running in
`build/i386-c5-shared-bitfield-native-build`; its outcome remains pending.

`BFieldExtU32` is now declared in the native public kernel header and bound to
the shared console implementation. Both original rebuild generations and the
native cross-build/386 audit pass (`build/i386-c5-public-bitfield-cross`). The
8 MiB native fixture resolves the public name and passes mask 63 over 99,072
pattern/start/width combinations against the bit-by-bit oracle, including the
normalized original-width comparisons (`build/i386-c5-public-bitfield-native`).
The fixture delivered to the guest matches its pinned source. Its 59.546351-second
startup observation was concurrent and is not an isolated timing gate. Raw
wider original-ABI return parity remains outside this fixture's scope.

The native kernel also publishes `BFieldOrU32`, used by the original archive
compressor. Its implementation performs the original unaligned eight-byte
read/OR/write using a shifted U32 pattern. The pinned original and 64 MiB
native fixtures pass mask 15 for four patterns at 128 bit positions against an
independent per-bit oracle, checking the surrounding 32-byte buffer; inputs
are unchanged (`build/i386-bit-field-or-reference` and
`build/i386-bit-field-or-native`). Both original rebuild generations and the
native cross-build/386 audit pass (`build/i386-bit-field-or-cross`). The native
62.462171-second startup observation was concurrent, not an isolated timing
gate. These vectors do not test invalid addresses, concurrent modification, or
full archive compression.
