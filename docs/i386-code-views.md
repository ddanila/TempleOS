# Native saved and detached code contexts

The shared parser copies `CCodeCtrl` headers when parsing arguments, function
bodies, loop increments and stream blocks. Copies retain the fixed active-header
sentinel addresses and may temporarily describe the same instruction or auxiliary
list. Some headers are detached from `cc->coc.coc_next` before their lists are
appended later. These headers are views of compiler state, not independent owners
of every node reachable through them.

Native controls now keep allocation ownership separately. Each native instruction,
auxiliary record and saved header embeds an intrusive allocation record after its
public fields. The public layouts and returned object addresses keep their existing
meaning. The control owns one registry of these allocations; there is no separate
heap allocation for each registry record. Auxiliary records continue to own their
string, array, dimension and detached-symbol payloads under the shared release
policy. Those payloads must not acquire duplicate owners merely because headers
alias their enclosing lists.

Full control destruction walks this registry once instead of traversing possibly
aliased or detached code-context queues. It releases every owned record and payload,
then resets the active code header. Thus interruption after a push, during an
aliased view, or after detaching a header does not double-free or lose temporary IR.
Document preflight, owner pins and the existing control-unwind boundary still apply.

## Operations and shared behavior

- `I386COCSave` allocates and registers a copied header without changing active
  queues or the saved stack.
- `I386COCPush` saves the current header and links the copy onto the saved stack.
  Like public `COCPush`, it does not implicitly initialize a fresh graph.
- `I386COCPopNoFree` restores the top saved header and returns that still-owned
  header, matching public `COCPopNoFree`.
- `I386COCHeaderFree` releases only a detached header. Its IR remains independently
  owned by the control. A header still on the active saved stack cannot be freed.
- `I386COCAppend` appends a detached header's lists to the active lists and consumes
  the header. It rejects a foreign control's header or one still on the saved stack.
- `I386COCDiscard` releases the current valid graph and unregisters its nodes. It
  can report label diagnostics through a callback, without implementing public
  compiler exception policy. Other header views remain allocated; callers must
  not restore a view of a graph they have discarded.

Header copy, restore and list append are shared with the public compiler through
`COCCopy`, `COCSave`, `COCRestore` and `COCJoin`. Appending an exact copy of the
active list now leaves its links intact, rather than changing the first node's
backlink to the tail. Both instruction and auxiliary lists handle this case.
The shared payload release remains unchanged in meaning; optional record-release
callbacks let the native path unregister records while the public path uses Free.

All native operations require the current live owner, or exclusive access to an
unbound control, and preserve caller IF. Failed allocation leaves the active queue
and saved stack unchanged. Discard holds a per-control busy flag and, for bound
controls, the task's compiler busy flag. Diagnostic callbacks may yield but must
return normally; reentrant mutation and deletion are rejected for both bound and
unbound controls. Arbitrary corrupted graphs or stale pointers are not supported.

Native IR and header allocations must use these managed services; raw heap frees
would bypass their ownership registry. Wiring public allocation, optimization-node
replacement and parser/AOT error policy to the native services remains required.
These are bootstrap compiler interfaces, not a new application allocation API.

## Integration and verification

CompilerRuntime version 18 exposes save/push/pop/header-free/append in its 108-byte
record and extends discard with diagnostic callback/context arguments. Its twenty
imports are unchanged. FileRuntime version 9 validates this dependency without
changing its 32-byte record or eighteen imports. Kernel exports remain 43.

The standalone recovery probe creates both a saved and a detached header aliasing
its failed child's IR. Native exception unwind must reclaim them and the IR once.
Retry exercises save, alias append, push, pop, header release and discard before
releasing the replacement child. Both boot and worker phases restore heap counts.

The task-symbol fixture exercises the public for-loop increment save/pop/append
sequence and checks forward/backward list links and the resulting 1,2,3 order.
It tests alias append, foreign/live-stack header rejection, allocation failure on
a fragmented exhausted heap, and owner cleanup after every queue view is dropped.
Existing payload and nested-context cases remain. The lexical-state fixture adds
unbound-control diagnostic reentry rejection and destruction with an aliased saved
header left after its graph was discarded. Both fixtures run with IF clear/set.

Both x86-64 rebuild/reboot generations, all 233 native function cases, both ownership
fixtures and the complete standalone 8 MiB QEMU/486 suite pass, including module
rejection checks and executable-region instruction audits. The test transfer and
heap boundaries remain 384 KiB/0x70000 for task symbols and 256 KiB/0x50000 for lexical
state. No standalone boot reservation was increased.

The kernel is 389336 bytes; with its 2160-byte loaded stage it occupies 391496 of
393216 bytes, leaving 1720. CompilerRuntime uses 227448 image / 227464 heap bytes,
FileRuntime 124584 / 124600, and the temporary probe 89256 / 89272, reclaimed after
its task phase. These pre-commit builds have source hashes in their manifests.
Strict 386SX/DX/no-387 acceptance, full native parser/JIT and self-hosting remain open.

Removed optimizer instructions can now be retired without reusing their storage.
Discard collects them once all other code records are gone; control destruction
always reclaims them. See [i386-ir-retirement.md](i386-ir-retirement.md).
