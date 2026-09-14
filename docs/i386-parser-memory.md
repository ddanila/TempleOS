# Native parser allocation ownership

CompilerRuntime ABI 25 adds `parser_alloc` and `parser_free`, making the service
record 144 bytes. Allocations retain their exact requested heap size. A separate
per-control registry tracks their lifetime without appending metadata to class,
member or dimension payloads, whose validators depend on that size.

Allocation requires a valid current owner or an exclusively owned unbound control.
Invalid setup/size returns null. Allocation failure throws `OutMem`; failure to
allocate the tracking record first releases the new payload. Both allocation and
registration run with interrupts saved and restored. Explicit release only accepts
an allocation in that control's parser registry; null is a no-op for a valid owner,
and foreign or already released pointers return false.

The registry remains live through IR cleanup and control deletion's lexer cleanup.
Their release callback
removes a matching tracking record when freeing its payload. This allows storage
allocated before or after a misc node to become that node's owned payload without
a second free during control deletion. Final control release reclaims registered
allocations that were never linked into a graph. The existing IR ownership registry
and parser-stack ownership remain separate.

Only allocations made by this service are tracked automatically. Existing lexer
strings and other transferred buffers still need explicit ownership plumbing in
the frontend adapters. Live lexer token replacement still uses the lexer's own
allocator; parser allocations must not be handed to that path without an adapter. Callers must unlink pointers before explicit release and
must not retain or publish these allocations beyond the compiler control's lifetime.
This does not implement durable symbol/code publication or arbitrary graph aliasing.

Native probes check exact sizes, zero fill, explicit/foreign/double release,
allocation-before-misc cleanup, linked array dimensions, detached temporaries and
failure at both payload and tracking-record allocation. They run on boot and worker
tasks and require exact heap, control, task-reference and interrupt-state recovery.
This infrastructure supports the remaining declaration/class adapters; it does
not yet compile `Kernel/Types.HH` or provide the full native frontend.

The boot and worker probes pass, including immediate rollback at both allocation
failure points. Dedicated lexer-state and task-symbol tests and the complete
standalone suite also pass. The retained compiler image is 768184 bytes (768200
heap bytes); the kernel is 389440 bytes. The standalone guest uses an emulated 486
with 8 MiB, so strict 386SX/DX acceptance remains unproven.
