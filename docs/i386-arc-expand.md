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
chain. The whole-archive API still needs size/type validation and output ownership
before this can be connected to file reads.

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
