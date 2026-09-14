# Native optimizer instruction retirement

`Compiler/OptLib.HC` documents that optimizer tree links may still refer to entries
after `OptFree` unlinks them. Native instructions therefore need a distinction
between removal from the active queue and the end of their allocation lifetime.
Reusing the storage immediately would invalidate those borrowed references.

`I386ICRetire(heap, cc, node)` validates a managed instruction belonging to the
current control, unlinks it, and marks its allocation retired. The node's fields,
including its old next/last pointers, remain intact. No allocation or heap release
occurs, so retirement can succeed with an exhausted heap. Foreign, null, sentinel,
already-retired and incorrectly linked nodes are rejected without queue mutation.
Unbound controls retain their exclusive-ownership contract.

The queue unlink operation is shared as `ICDetach`; public `OptFree` uses that
helper and retains its existing immediate Free policy. The native service provides
the stronger lifetime needed before wiring the shared optimizer to its allocation
services. This is not a claim that the optimizer passes already execute natively.

## Reclamation boundary

A successful `I386COCDiscard` releases the current graph. After its callbacks have
returned, it collects retired instructions only if the control's allocation
registry contains no other records. Any live instruction, auxiliary record or
saved/detached header defers collection. Freeing a header by itself does not collect
retired instructions; a subsequent discard provides the explicit phase boundary.

Control destruction always reclaims remaining retired instructions together with
its other owned code allocations. This also applies to catch-boundary unwind and
task-exit cleanup. Thus saved views can keep removed-node data available, while
repeated complete discard/reuse cycles reclaim temporary storage before the next
compilation accumulates it.

Borrowed tree references may be inspected before that boundary. They must not be
used after collection, and stale queue headers must not be restored as if removal
had never occurred. Retirement is not reference counting or an immutable graph
snapshot. Callers still own the optimizer's valid graph and phase discipline.
All operations preserve caller IF and use the existing control/task reentry guards.

## Integration and evidence

CompilerRuntime version 18 adds `code_retire` in a 108-byte record, with twenty
imports unchanged. FileRuntime version 9 validates that dependency and retains
its 32-byte record and eighteen imports. The standalone failed-child probe keeps
a tree reference to a retired instruction while saved and detached headers exist;
exception unwind reclaims the whole control. Its retry retires the only instruction
and discards the graph, collecting that instruction before control deletion.
Both boot and worker phases restore exact heap accounting.

The task-symbol fixture verifies retirement with a fragmented exhausted heap,
unchanged wide instruction data and old links, surviving tree references under
allocation pressure, invalid/double retirement rejection, saved-header deferral,
and later collection. It performs 32 complete retire/discard/reuse cycles for each
initial IF state without heap growth, then checks full control-unwind reclamation.
The lexical-state fixture also retires an instruction in an unbound control whose
aliased saved header outlives graph discard.

Both x86-64 rebuild/reboot generations, all 233 native function cases, both ownership
fixtures, and the complete standalone 8 MiB QEMU/486 suite pass. Executable-region
instruction audits and service rejection checks pass. The kernel is 389336 bytes;
with its 2160-byte loaded stage it occupies 391496 of 393216 bytes, leaving 1720.
CompilerRuntime uses 227448 image / 227464 heap bytes, FileRuntime 124584 / 124600,
and the temporary probe 89256 / 89272, reclaimed after its task call. These local
builds have source hashes in their manifests; test transfer sizes are unchanged.

Public allocator/OptFree routing, optimizer execution, full parser/JIT and AOT
recovery, strict 386SX/DX/no-387 workflows and native self-hosting remain open.

The shared branch optimizer now uses this native retirement path through a
control-aware `OptFree`; see [i386-branch-optimizer.md](i386-branch-optimizer.md).
Other optimizer passes and the complete parser still require native integration.
