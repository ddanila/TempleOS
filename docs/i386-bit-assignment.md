# Native callable bit assignment

The native public kernel header includes `Kernel/I386/Bit.HH`, with the original
`BEqu` and `LBEqu` signatures and `_BEQU` / `_LBEQU` callable export names.
MemoryRuntime owns these bit-memory primitives alongside the retained memory
and string operations; their code has kernel lifetime. Public declarations own
only their metadata, so callable addresses survive compilation and task cleanup.
MemoryRuntime version 6 requires these bindings; the loader rejects version 5.

Both operations assign the bit according to whether the Bool value is nonzero
and return the previous bit. `LBEqu` selects `LBts` or `LBtr`; `BEqu` selects
`Bts` or `Btr`. The implementation reuses the existing backend's signed I64
bit-index calculation and native pointer-width address folding. It does not
truncate the bit index to 32 bits before finding its containing word.

The locked branches use hardware LOCK BTS / LOCK BTR. The module verifier
disassembles each implementation and requires the corresponding two instructions,
with LOCK on both locked branches and neither plain branch. This establishes the
emitted instruction contract, not a new multicore scheduling guarantee. Callers
must supply an accessible containing dword, including for negative or unaligned
bit strings, as with the existing native bit intrinsics.

`Kernel/I386/BitEquCheck.HC` is shared unchanged between the original x64 exports
and native public bindings. It checks 168 vectors / 504 calls across both
operations: twelve nearby signed bit positions, two offsets beyond signed
32-bit range, and Bool values 0, 1, 2, -1, 127 and -128. The wide-offset vectors
bias the base pointer oppositely so the effective access remains in the guarded
buffer on both architectures. Each vector checks the old-bit return, neighboring
bytes, an idempotent assignment and the opposite assignment. The 32-byte buffer
contains the full x64 qword and native dword accesses.

Native boot and worker public-header probes compile this complete corpus through
the retained compiler, call the real resident bindings, and then perform their
usual full symbol/storage reclamation checks. Interactive checks exercise a bit
above 31 and repeated locked/plain calls across console submissions. Original
Bit help metadata is published with the declarations.

This supplies the missing bit assignment operation used by original DocLock.
It does not implement DocLock/DocUnlock, public Yield, BreakLock or BreakUnlock.
Scheduler and pending-break semantics, exception cleanup and document lifetime
remain necessary before the original locking code can be integrated faithfully.

## Diagnostic compiler stack

The unchanged full corpus initially passed in the boot task but was rejected in
the diagnostic worker. Its saved exception call chain starts at
I386ParserStackCheck, followed by expression parsing and nested statement parsing.
The throw frame had 3768 bytes remaining on the 8192-byte stack; the parser keeps
a 4096-byte reserve. The private heap remained valid and returned to its prior
197344 used bytes after the rejected input. This was a compiler stack limit,
not evidence of incorrect bit assignment or exhausted heap storage.

The diagnostic compiler worker now has a 16384-byte stack and the same 524288-byte
private arena. The parser reserve and complete single-input corpus are unchanged.
Normal console stack sizing and the 8 MiB machine profile are unchanged. Local
failure evidence is saved in `build/bit-equ-stack-failure.json` and `.log`.
Native automatic stack growth remains separate unfinished work.

## Integrated verification

Both x64 rebuild generations and the full native suite pass against 1087 recorded
OS source hashes. Native boot and worker tasks each pass all 168 vectors. The
suite passes 127 console commands across 190 lines, exact VGA checkpoints,
startup-source recovery, diagnostic independence and all 17 module rejections.
Normal QEMU/486 startup at 8 MiB measures 16.401 seconds; diagnostics 151.783.

Public headers retain 172504 bytes. MemoryRuntime 6 uses 118344 image / 118360
heap bytes; the temporary CompilerProbe uses 660272 / 660288 bytes and is fully
released. Worker teardown returns 541856 bytes, including its larger stack.
The kernel remains 386680 bytes with 2440 bytes of bootstrap headroom.
