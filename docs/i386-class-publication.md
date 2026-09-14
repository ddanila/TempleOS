# Native class publication

CompilerRuntime ABI 29 (168 bytes) adds `publish_classes(heap, cc, source)`.
It transfers completed private class graphs from a compiler control to its current
task's symbol table. The class records keep their addresses, so member/type links
within the transferred group remain valid. A successful transfer empties the source
buckets; source-table storage and unrelated parser temporaries remain owned by the
control. Destruction of that control no longer releases the transferred payloads.

The source must be the control's active global/hash table, with a plain `CHashTable`
and correctly sized bucket array allocated through `parser_alloc`. Its parent must
be the current task's destination table. Both tables must be unlocked. Publication
rejects compiler errors, saved hash contexts, outstanding lexer snapshots,
any registered IR storage,
non-class roots, duplicate source names and names already in the destination's own
table. Inherited names may be shadowed without replacing their existing records.

Validation uses the shared `SymbolHashVisit` ownership traversal. Every owned
payload must have exactly one allocation record in this control; source-table
storage, control-owned strings/stacks, and lexer file records, filenames or buffers
cannot be transferred as symbol payloads. A
scratch array collects records without detaching them. Foreign or repeated
ownership, invalid setup and scratch allocation failure return false without
changing source/destination contents or allocation ownership. Once validation
passes, the operation removes the selected tracking records and links the class
roots into the destination without further allocation. Interrupt state is restored
on every return; the transfer requires exclusive current-task access throughout.

Inputs must be live, valid, acyclic symbol graphs. This is an ownership transfer,
not a validator for arbitrary pointers. Borrowed references follow the existing
symbol policy: base/forward/member type links and borrowed executable/static
storage must remain live in the destination environment or transferred group.
The operation does not publish function bodies, global data or executable buffers.
It does not replace existing destination symbols or make their mutation safe.

`SymbolHashVisit` and its member/list helpers enumerate owned storage without
rewriting graph fields. Existing destructors use that same traversal with their
release callbacks. Explicit member-list deletion still clears the containing
class/function's member state. This keeps transfer and deletion ownership policies
in one implementation.

The native fixture parses the unchanged `Kernel/Types.HH`, publishes its six scalar
unions, destroys the original control, then uses a fresh control to compile and
execute an expression using their members, pointer size and narrowing casts. After
all users are gone it detaches and deletes the classes, checking exact heap/task/
exception/interrupt restoration. Nine rejection cases cover a destination name
collision, foreign payload, duplicate payload, scratch OOM, destination supplied
as source, live IR, an error-bearing control, and current-token/lexer-filename
aliases. These run on boot and worker tasks.

Permanent bootstrap registration and a complete retained frontend environment are
still required. General code/data/function publication, source metadata, interactive
compilation, DolDoc and native self-hosting remain under `PLAN.md`.
