# Native task symbol scopes

The public task model creates a local hash table for each child and chains its
lookup to the parent's table. Native tasks now follow that structure: `hash_table`
is task-local, while `CI386TaskSymbols` owns its allocation and records the parent
scope. The root borrows the existing resident symbol table. Children use 1024
buckets by default, matching the public task constant; the initializer can select
another power of two for a specific bootstrap configuration.

Spawning creates the child's file context and symbol table before adding it to
the runnable list. Symbol state uses the child's private heap when available and
the task allocation heap otherwise. Failure reclaims the unpublished state,
including an already-cloned file context, without changing parent references.
A successful child pins its parent scope until the child's symbol state is
reclaimed. Consequently, a parent can finish, but its task and private arena cannot
be reaped while a child still resolves names through that table.

`lifetime_refs` is a native task-lifetime counter shared by scope dependencies and
borrowed file contexts. Reaping rejects outstanding references before running
state destructors. It does not prevent a task from finishing; ATA ownership still
uses the separate finish-blocking I/O pin. File replacement also retains its
existing per-state busy check. Reference overflow rejects new borrows/clones.

The symbol destructor drains owned local entries using the existing public
`HashDel` field-ownership policy, then frees the empty native table and releases
the parent reference. It does not delete the borrowed root table. Every owned
entry and owned subsidiary allocation must belong to the scope's heap; borrowed
code and referenced symbols retain their declared lifetimes. Graphs must be
valid, unlocked, exclusively owned and acyclic. Corrupt allocations or invalid
provider callbacks are not a failure-atomic disposal contract.

## Retained compiler integration

CompilerRuntime version 12 exposes root scope initialization. The retained module
owns clone/destructor code for the kernel lifetime; it imports the kernel's native
hash table new/validate/delete functions and shares symbol destruction code.
The service table is 56 bytes, with twenty imports and forty kernel bindings.

Root scope initialization follows compiler-module validation. Subsequent keyboard
and compiler workers inherit local tables chained to the resident root symbols.
The disk compiler probe initializes controls with the current task's table and
uses that scope's heap for input, lexical state and codec allocations. Keeping
these allocations in the same heap is required for later definition cleanup.
The compiler worker reserves 128 KiB, allowing its include decompressor to use the
existing roughly 70 KiB codec workspace; the keyboard worker reserves 8 KiB.
These fixed arenas remain a bootstrap allocation policy, not the completed public
`CHeapCtrl`/task/code-heap implementation.

Explicit unbound compiler controls still borrow their symbol table. The new
current-task factory binds controls to the scope owner and pins it until deletion;
see `i386-task-compiler.md`.
Public task records, control-list cleanup on task exit, the complete constructor's
filename/default-name and bitmap selection, parser/JIT and self-hosting remain
required integration work.

## Verification

`python3 tools/test-i386.py --task-symbols` uses real cooperative contexts with
FS/GS binding. It checks local shadowing, fallback to a parent and then root,
sibling independence, parent-finished/grandchild-live lookup, rejected early reap,
and final reclamation of owned definitions and all scope state. The grandchild
uses the outer allocation heap, while its parent uses a private arena. Small
private arenas and saturated references exercise spawn rollback, including file
state created before a symbol-allocation failure. Root-table retention and file
borrow interaction are also checked.

The standalone boot probe verifies that root and worker controls use the proper
hash-table chain and reclaims temporary allocations in the corresponding heap
after nested includes and archive errors. The ATA fixture covers file borrows
across real I/O after adding task-lifetime references. These checks remain on the
QEMU/486 development profile and do not establish strict 386 hardware support.

Two x64 rebuild/reboot generations, native task-symbol, task, ATA/file, hash-table
and exception checks, and the full standalone suite passed. The task fixture uses a bounded 192 KiB transfer ending at its 0x40000 arena.
The expanded scope/constructor fixture uses 256 KiB and an arena at 0x50000.
The kernel links `HashTableCore.HC`; the full `HashTable.HC` still includes resizing
for callers that need it, and the resize regression passes. Omitting that unused
3296-byte routine from the bootstrap keeps the fixed reservation intact.

The native kernel is 389512 bytes. With the 2160-byte loaded stage, it leaves
1544 bytes in the unchanged 393216-byte reservation. CompilerRuntime retains
173192 heap bytes and FileRuntime 116064; the temporary probe reclaims 74392.
The two worker arena reservations total 139264 bytes, an increase of 131072 over
the previous two 4096-byte arenas. The native integration still fits the 8 MiB
development profile, but peak full compiler/editor memory remains unverified.
