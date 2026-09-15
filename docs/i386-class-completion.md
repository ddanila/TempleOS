# Native class completion transactions

A native source submission can complete an ordinary forward class declaration
published earlier in the same task's symbol scope. Parsing uses a private class
record. The published layout, pointer variants and member graph stay unchanged until
publication has validated the complete input and reserved the
storage needed for ownership transfer. Ordinary symbol/member lookup counters
can still advance during parsing.

`CPrsExpressionServices.class_view` is an optional environment callback. The host
and isolated parser probes initialize it to null, preserving existing descriptor
lookup. The native frontend maps a pending class's published descriptor and pointer
variants to its private definition for token/type lookup, emitted expression types,
member lookup, forwarding and size calculations. Existing holder records can thus
refer to the old identity while code in the defining input sees the new members.

Publication rechecks each target. It must still be an ordinary empty forward class
in the task's own table, with metadata allocated in the same heap. A completion
published by a nested input invalidates an older pending completion. The older
input cannot overwrite it. Inherited declarations in another task's table remain
borrowed; this operation does not transfer child-owned metadata into a parent's
longer-lived scope.

After all validation and allocation succeeds, publication rewrites private class,
base, member, global and function-signature references to the stable published
identities. It rebuilds local-variable type indexes because their ordering depends
on descriptor addresses. Anonymous callback signatures are traversed as owned
metadata. The completed members and source metadata move to the published root;
the private descriptor is reclaimed with the compiler control. No extra descriptor
is retained merely to implement forwarding.

The published name allocation stays stable throughout. Private definitions borrow
that name, so generated `lastclass` arguments retain a live address. Old source
metadata is released when new source metadata commits. Shared graph ownership
validation still checks every transferred allocation; only the private completion
root and its explicitly borrowed name are excluded from that transfer.

Before enabling a completed layout, the frontend checks earlier private objects,
class members, bases and defined functions for by-value uses of the incomplete
type. Their storage cannot be resized retroactively, so completion rejects these
inputs before code can access newly introduced fields. The check also applies to
private forward declarations completed within one input. Pointer uses and inactive
forward/callback signatures remain valid.

Abandoning a control or failing to parse/publish leaves the old definition intact.
This is a class-metadata transaction. Previously executed command side effects and
preprocessor definitions retain the existing input lifecycle semantics.

The completion probes cover basic publication, syntax-error rollback, abandoning
a successfully parsed definition, foreign-metadata rejection, allocation-failure
retry, a nested competing
completion, mutually linked types, callbacks and inherited/member type references,
local type indexes, stable names, forward function fixups, repeated forward
declarations, invalid early layouts and completion of an empty class. Boot and
worker phases check heap/control/task-state reclamation. The keyboard test also
submits a failed definition, retries it, then uses the completed type through a
holder declared in an earlier submission.

[Native public-header loading](i386-public-headers.md) now uses an explicit macro
transaction, allowing failed include guards and class definitions to be retried
together. Ordinary input keeps immediate macro publication. Remaining language
providers and public kernel-service semantics are separate integration gates in
[PLAN.md](../PLAN.md).
