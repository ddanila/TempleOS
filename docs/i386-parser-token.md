# Parser token ownership

CompilerRuntime ABI 26 adds `parser_token`, growing the service record to 148 bytes.
This entry uses the existing native lexer/include service and tracks returned
`cur_str` buffers in the compiler control's parser registry. When a parser takes
an identifier or string by clearing `cur_str`, that allocation remains registered
until explicit release, graph-payload release or control deletion.

When the lexer still owns its current string, the wrapper temporarily clears the
tracking record's payload pointer before calling the raw lexer. The lexer can then
replace/free the old string normally. On success the record is reused for the
current string. On failure, final lexer cleanup owns that string and final parser
cleanup releases the empty tracking record. A newly returned string remains
lexer-owned if allocating its first tracking record fails.

Invalid owner/setup returns -1 without reading a token. Negative raw lexer results
increment the error count and throw `Compiler`; allocation of a tracking record can
throw `OutMem`. Failed parsing still requires full control unwind. Callback and
source lifetimes follow the existing lexer/include contracts.

Use this token entry consistently within a parser environment. Mixing raw token
calls with tracked current strings bypasses bookkeeping. Transfers must clear
`cur_str` before attaching its value elsewhere, and explicit release requires
removing the owning reference first. This covers returned token strings; it does
not automatically register arbitrary external allocations or implement durable
symbol/code publication.

The expression/type probes now use this entry. Additional boot/worker probes cover
identifier transfer without graph attachment, ordinary token replacement, quoted
string transfer into a misc payload, EOF cleanup, replacement failure with an
existing tracking record, and first-record allocation failure after lexing succeeds.
Every path requires exact heap, control, task-reference and interrupt-state recovery.
Native declaration/class integration and compilation of the original public scalar
unions remain required by `PLAN.md`.

The complete standalone suite and dedicated lexer-state/task-symbol ownership
checks pass. The retained compiler image is 772624 bytes (772640 heap bytes), and
the kernel is 389448 bytes. The standalone guest uses an emulated 486 with 8 MiB;
strict 386SX/DX acceptance remains unproven.
