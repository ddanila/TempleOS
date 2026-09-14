# Owned native code buffers

`Compiler/I386/EmitCore.HC` contains the byte, little-endian dword and byte-string
writers used by the production i386 backend. `CI386Out` now supplies a reserve
callback, separating byte generation from the host allocator. The x64 backend and
expression entry initialize their output through `I386OutInit`; native callers
obtain an owned buffer through the retained `out_new(heap, cc)` service.

## Allocation and lifetime

The native buffer is a registered compiler-control allocation (kind 5), owning its
current byte allocation. Growth starts at 64 bytes and doubles with a checked
signed 32-bit size ceiling. The reserve operation allocates and copies before
releasing the previous allocation and publishing the new pointer/capacity. Failed
allocation throws `OutMem`, preserving the old bytes, count and capacity; it can
be retried after memory is reclaimed. Invalid reserve sizes throw `Compiler`.

Native allocation, growth and deletion preserve the caller's IF. Growth currently
protects the copy as well as the allocator operation with interrupts disabled;
large-buffer latency still needs measurement on the vintage hardware profile.
The builder is compiler-internal state: use it only from its current owner, do not
share or mutate it from interrupt handlers, and do not alias an append's input
with its growable output. Reserve callbacks must satisfy the request or throw.
Byte pointers become invalid after successful growth, deletion or control unwind.

`out_del(heap, cc, out)` rejects a foreign control and frees the buffer and its
ownership record. Full control destruction/unwind also releases both allocations,
without requiring a catch handler to retain the builder pointer. IR discard and
saved-header release leave the buffer alive: code output is owned by the control,
independently of temporary graph views. As with other live ownership records, an
output buffer defers collection of retired IR until a later discard boundary or
full control cleanup.

These are temporary compiler output buffers, not published code objects. Callers
must not retain function pointers beyond the owner lifetime. Persistent JIT code
publication, relocation, module/task references and unloading remain separate
integration work. The production backend still needs its other allocation, symbol,
assembly and target-execution dependencies before it can compile natively.

## Interfaces and verification

CompilerRuntime ABI 21 adds `out_new` and `out_del`, making its record 124 bytes.
FileRuntime ABI 12 validates the new compiler dependency; its own record remains
32 bytes. The compiler's 21 imports and the probe's 56-byte ABI 5/17 imports remain
unchanged. The reserve callback belongs to the retained compiler module.

The standalone boot/task probe includes the shared byte writer and uses native
owned buffers. In 64 iterations per phase it emits 257 NOPs followed by
`MOV EAX, imm32; MOV EDX, imm32; RET`, checks every emitted byte, executes the code
and verifies its 64-bit return. Each iteration crosses the 64/128/256-byte growth
boundaries, rejects deletion through a foreign control, retains code across IR
and saved-header cleanup, and checks exact reclamation on deletion.

The probe also exhausts every free heap span, verifies failed growth and failed
builder construction, frees the filler allocations and retries growth. It rejects
an overflowing reserve, then throws and unwinds with a live builder. Exact heap
counts, task references, active controls and IF must return to their baseline.
Generated code is checked byte-for-byte; build-time executable-range audits cover
the cross-compiled emitter and probe. This remains QEMU/486 development evidence,
not strict 386SX/DX or physical-hardware acceptance.
