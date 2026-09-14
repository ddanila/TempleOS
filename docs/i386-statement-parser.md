# Shared statement parsing

`PrsStatementCore.HC` contains the production statement parser, including loops,
conditionals, labels, nested switch start/end sections, declarations, returns,
try/catch, stream blocks and assembly dispatch. Existing public entries construct
services and call the same core. `PrsCompileFlags.HH` shares the unchanged flags.
This is preparation for native frontend integration; no native statement service
is published yet.

`CPrsStatementServices` borrows global, symbol, initializer, declaration, type and
expression services. It adds saved-code-control recovery, assembly parsing/AOT
joining/JIT fixups, task symbol lookup, immediate command execution and source
inclusion. Providers must remain valid across recursive parsing and compile-time
execution. Error reports must throw as in the existing parser.

Switch tables are initialized through pointer assignments rather than eight-byte
stores, so the same code respects native pointer width. Case-range enumeration
stops at its last value before incrementing, avoiding signed wrap at `I64_MAX`.
Intrusive queue helpers likewise store pointers through typed fields. These changes
do not alter the language's switch range checks or nested-section behavior.

Native providers must register temporary switch records, jump tables, saved code
controls, stream records and symbol contexts with the compilation owner. The core
preserves the original exceptional-path limitations (including switch allocation
leaks); ordinary success cleanup alone is not sufficient for native recovery.
Stream execution temporarily changes the symbol context and compiler flags, then
transfers a nonempty generated body to source inclusion or releases an empty body.
An adapter must preserve that ownership transfer and restore/unwind all state when
execution fails. Assembly joins and immediate execution require target-specific
linking and durable code publication, which remain unfinished.

The regression corpus executes a singleton case range at `I64_MAX` in both the
host and generated i386 program. Rebuilds and cross-builds exercise the shared
parser in the host compiler; they do not establish native frontend execution.
