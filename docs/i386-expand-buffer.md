# Owned native archive expansion

`I386ExpandBuf(heap, archive, archive_size, size)` reads a borrowed archive extent
and returns an owned allocation containing the expanded bytes plus a NUL. The
optional size excludes that terminator and changes only on success. Embedded NULs
remain data. Empty archives produce a one-byte allocation. Callers release output
with I386HeapFree; source storage remains borrowed and live throughout the call.

Header checks precede allocation: the readable extent must contain the 17-byte
header, declared sizes must be nonnegative and fit the supplied extent/address
space, the type must be CT_NONE/CT_7_BIT/CT_8_BIT, and output must fit the native
allocator's size range. CT_NONE copies only a declared body that fits. Compressed
input must produce the complete declared output, empty its pending stack and
leave fewer than eight padding bits inside its declared compressed length. Empty
compressed archives must have a header-only compressed length. Bytes outside the
declared compressed length may belong to the caller's surrounding extent.

For compressed data, the existing constructor owns the control and stack. A
per-call bitmap tracks initialized dictionary entries. A checked reader requires
a literal first code, rejects undefined references, bounds chain walks to stack
capacity and prevents linking the current entry to one of its descendants. This
maintains an acyclic dictionary before the shared decoder follows its links.
The special current-entry code retains its original expansion behavior. Callback
context is passed explicitly; no global or task-local scratch state is introduced.

Failure reclaims output and temporary control/stack allocations and preserves the
optional size. Success retains only the output. Heap operations preserve IF; codec
work runs in the caller's interrupt state. Heap and source must remain exclusively
owned/live, and archive_size must describe readable memory. This API validates
archive structure; it cannot verify the caller's memory mapping or detect every
payload alteration without a format checksum.

## Verification

The arc-expand fixture adds six owned expansions of original-compressor vectors,
checking every source byte, exact allocation size, termination and reclamation in
both interrupt states. It also covers binary CT_NONE data, all empty types, null
and wrapping extents, header/type/size failures, short data, invalid first and
undefined codes, under/overstated output, the special current-entry case and direct
cyclic/undefined/ancestor chain checks. Thirty-two payload bit mutations must either
produce a correctly owned result or fail with unchanged size and reclaimed storage.

Seven exhausted arenas cover output, control and stack allocation failures. An
exact-fit 102600-byte arena expands the 32768-byte fixture and retains only its
32792-byte output span. The existing 18 streaming expansions, bit-reader failures,
x64 fixture checks and 386 instruction audit remain in the same test command:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --arc-expand
python3 tools/build-i386-kernel.py --test
```

Whole-archive expansion is available as a native component. It is not yet wired
into public FileRead, .Z-name fallback, resident-file records or include dispatch.
The new code stays outside the standalone bootstrap pending file-service module
integration; this does not establish the complete interactive or rebuild memory
profile.
