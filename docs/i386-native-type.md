# Native shared type parsing

CompilerRuntime ABI 29 (168 bytes) includes `parse_type`, introduced in ABI 24.
The entry invokes the complete `PrsTypeCore.HC`, including its shared array-dimension
and variadic-argument helpers. It borrows a populated `CPrsTypeServices` and checks
the compiler control's current owner and task stack before parsing. Invalid setup
returns null; grammar errors throw through the supplied diagnostic callback.

The expression environment can call this entry for HolyC postfix casts. The
native probes connect the real lexer, built-in type registry and type parser to
the expression parser and backend. They cover narrow integers, pointer truncation,
pointer stride/difference, type sizes, unknown types and excessive pointer stars.
The fixture deliberately fails if a callback outside this coverage is invoked.
It supplies no substitute type grammar. These cases use intrinsic names such as
`U32i` and `I64i`: the public `U32`/`I64` union classes and their member views must
still be compiled from `Kernel/Types.HH` when native declaration parsing is wired.
They must not be replaced with bare aliases that omit those members.

Class/function joins, lexical snapshots, array-bound evaluation, allocation,
identifier duplication and member construction remain explicit callback contracts.
The caller owns partial dimensions and symbol graphs, including records detached
while parsing. Successful type parsing does not make those graphs durable or
register arbitrary callback allocations with the compiler control. Providers must
arrange complete failure cleanup and publication lifetimes before general source
compilation. The borrowed service graph must stay live through recursive calls.

Expression and type entry share the task-stack reserve check. Parser-stack bounds
and owner validation remain in effect, and the existing expression recovery tests
continue to run alongside the type cases. Full declaration/statement integration,
native compile-time execution, linking and self-hosting remain unfinished.

All 44 expression/type checks pass on boot and worker tasks, including the prior
expression recovery cases. The full standalone suite passes with an emulated 486
and 8 MiB, including instruction auditing, pixel-exact VGA/input and incompatible
module rejection. This is not strict 386SX/DX acceptance. The retained compiler
image is 761344 bytes (761360 heap bytes); the kernel remains 389432 bytes.
