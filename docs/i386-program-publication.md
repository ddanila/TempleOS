# Task-owned native program publication

CompilerRuntime ABI 34 (196 bytes) adds `publish`. It transfers complete private
definitions from a retained frontend into the current task's symbol table. The
input control can then be destroyed while fresh controls compile and execute code
using those definitions. The transfer includes classes, completed functions,
globals and string definitions. Same-source forward calls may resolve before
publication; remaining private call fixups and unresolved functions/imports are
rejected.

## Two ownership paths

Standard symbol graphs retain their existing ownership traversal. Names, source
metadata, members, default strings and owned global data become task-table payloads
and are released by normal symbol destruction.

Executable code and static-member storage follow a separate task lifetime.
`CI386TaskSymbols.storage` holds allocation groups reclaimed after the task's owned
symbols. Publication retains every live registered frontend output, including
anonymous command and initializer code: a global or static pointer can refer
into one of their literal pools.
The retained group is sized for its actual payload count rather than the scratch
validation capacity. Children retain their parent's symbol scope through the
existing lifetime references, so inherited code and static storage stay live.
Explicit global aliases retain borrowed-address semantics, including address zero;
publication never treats an alias address as an owned allocation to release.

Successful publication empties the private source table and removes code from the
frontend's execution registry. Old `execute`/`release` handles no longer own that
code; use the published functions normally or compile a new command against them.
Compiler-control teardown frees the remaining input, parser state and output
metadata without reclaiming transferred payloads. Published code still borrows
the retained numerical runtime and any other referenced task/ancestor symbols.

## Validation and failure behavior

The source must be the frontend's private table directly above the current task's
table, with no parser error, saved lexer/context frames, active function or pending
IR allocations. Validation rejects destination/source name collisions, incomplete
functions, unresolved relocation lists, unregistered function bodies and invalid,
borrowed or duplicate owned payloads. Lexer buffers and compiler scratch objects
cannot be transferred as symbol storage.

All validation and allocation precede ownership changes. Failure returns false
with the private table, allocation records and destination storage unchanged.
Success detaches the payload records, installs the storage group and moves roots
into the destination table. Publication currently uses the same synchronous,
interrupt-masked discipline as class publication; latency and scalability with
large programs still require work against the vintage-hardware acceptance goals.

Publication is not an execution transaction. Earlier commands can already have
side effects. A failed later input control can be unwound without deleting
definitions published by earlier controls. Redefinition/replacement and arbitrary
program unloading need explicit dependency rules; the current entry rejects name
collisions and retains storage until task teardown. The root table is borrowed
under the existing task-symbol contract; callers must detach external references
before destroying a root scope or manually deleting published definitions.

## Verification

The native probe runs publication cases during boot and from a worker task. It
destroys the originating control, then uses fresh controls to call functions,
recurse, mutate static state, access aggregates/default strings and read both
function, anonymous-command and global/static initializer literal pools. It compiles malformed later input,
unwinds that input and verifies the earlier definitions remain usable.

Negative cases cover collisions, foreign/duplicate metadata, heap exhaustion,
pending IR, existing compiler errors, unresolved functions, foreign code pointers
and aliased static storage. The fixture models a resolved borrowed alias at address
zero and checks its address without dereferencing it; native system-symbol linking
remains separate work. Repeating publication of an empty source must allocate no retained
storage. Failed transfers must preserve exact heap counts and
source-table membership. Successful transfers invalidate the old executor handle.
The fixture exclusively removes its test roots/storage afterward and requires
exact restoration of heap, control, reference, exception and interrupt state.

The separate task-symbol suite exercises production teardown of storage groups
on root, worker and grandchild scopes. A finished parent cannot be destroyed while
its child or compiler control retains it; its storage remains readable by the
child. Final teardown restores the complete heap allocation baseline.

Run `python3 tools/test-rebuild.py`, then
`python3 tools/build-i386-kernel.py --test` and
`python3 tools/test-i386.py --task-symbols`.

Complete public task/answer APIs, full assembler/try/generator
integration, DolDoc and native self-hosting remain required. These QEMU/486 checks
do not establish strict 386SX/DX or physical-machine acceptance.
