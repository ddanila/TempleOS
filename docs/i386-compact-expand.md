# Compact private archive expansion

The 8 MiB diagnostic previously failed after phase-one DISK READ when archive
expansion requested a 65,676-byte control. Its largest free block was smaller
than that request. Moving allocations to the high end did not help.

The private whole-buffer reader now uses 4,096-entry U16 prefix, next-link and
hash-head arrays, a byte suffix array, validity bits and the 4,096-byte expansion
stack in one 33,328-byte allocation. Links encode index+1, retaining zero as the
null link. The original bit-width transitions, dictionary leaf-recycling order,
current-entry special case, chain validation and trailing-bit rule are retained.

Public CArcCtrl layout, the compression format, compression implementation and
streaming ArcExpandStep remain unchanged. Only I386ExpandBuf's temporary private
workspace changes. Its returned allocation, size/NUL contract, failure cleanup
and interrupt-state preservation remain the same. The workspace consumes 33,344
arena bytes instead of 69,808, saving 36,464 bytes. The focused 32,768-byte output
case needs 66,136 arena bytes instead of 102,600.

## Validation

`tests/guest/i386-arc-expand/Reference.HC` freezes the previous checked decoder,
with only its entry point renamed. The parity audit is preserved in
`build/i386-compact-expand-reference-parity-v1.json`. The differential fixture
runs six original compressed vectors and 64 bit mutations per vector: 390 cases,
comparing acceptance, reported size, every output byte including the terminator,
and heap cleanup. The vectors include seven- and eight-bit inputs, dictionary
width growth/recycling, repeated data, random data and single literals.

`build/i386-compact-expand-corpus-v5` passes that differential corpus plus the
existing streaming, owned-buffer, malformed-input, IF and allocation-boundary
checks on emitted i386 code. Both bootstrap generations pass in
`build/rebuild-compact-expand-v2-verified`.

The new longer corpus uses a 180-second runner timeout by default. Other corpora
retain 20 seconds, and --runner-timeout overrides either (1..3600). The v4 run
hit the previous hard-coded 20-second limit; subprocess.run terminated its guest
and the process was confirmed absent before retrying. Earlier preserved runs
exposed fixture errors: the allocation boundary initially assumed a 24-byte
rather than 16-byte arena header, and an enlarged differential-test arena
contained the runner stack. The corrected test uses the original arena and
mutates/restores its borrowed vector bytes.

The full diagnostic and application gates must be assessed separately; passing
this corpus alone does not close C1–C5.

## Integrated candidate and remaining capacity limit

The cross-build and instruction audit pass in `build/i386-compact-expand-cross-v2`.
Its post-export audit matches 1,725 source files and 26 helpers. Its normal image
is byte-identical to cross-v1's normal image, which passes exact welcome pixels,
suspended clear and subsequent input at 8 MiB TCG with unchanged inputs in
`build/i386-compact-expand-welcome-v1`.

The full cross-v1 diagnostic fails before the second CompilerProbe load. The
unchanged interface-226 baseline reproduces that failure in
`build/i386-compact-expand-baseline-heap-v2`, with unchanged inputs: the requested
module is 575,322 bytes, main capacity is 6,791,680, used is 6,276,320 and largest
free block is 483,312 bytes. The compact candidate fails at the same load with
used 6,284,512 and largest free block 475,120. Its retained footprint at this
point is 8,192 bytes larger; the workspace saving applies during expansion.
Neither run reaches the earlier interface-225 decompression failure. That gap
is therefore not proven closed, and the full 8 MiB diagnostic remains unqualified.

The baseline v1 profiler timed out after 180 seconds during header loading and
terminated its guest; both process IDs were confirmed absent. V2 used a fresh
output directory and a 1,200-second observation limit. Both records are preserved.
The completed cross-v2 packaging run preserves a normal build manifest after
cross-v1's full-test failure, without overwriting its logs or images.

A follow-up can remove the no-longer-used streaming decoder inclusion from
FileRuntime (the public ConsoleRuntime implementation is separate), then address
the compiler-probe/root-header peak. The same diagnostic assertions must remain
in scope; this compact workspace change alone is not a full-suite fix.
