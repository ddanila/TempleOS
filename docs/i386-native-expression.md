# Native shared expression parser

CompilerRuntime ABI 26 (148 bytes) includes `expression(heap, cc, services,
precedence, end_exp, stack)`, introduced in ABI 23. It executes the complete
production `PrsExpressionCore.HC` inside the retained native module. The service environment
remains caller supplied: this entry is not yet a complete native frontend or a
public source compiler. Type/declaration, string, symbol and other callback
providers must implement their full contracts before accepting general source.

The entry requires the current owner of a native compiler control and a populated
`CPrsExpressionServices`. Invalid setup returns false. Errors during parsing throw;
callers must unwind the failed control before reusing their compilation state.
Borrowed service records, types and precedence tables must remain live throughout
recursive calls. Callbacks run under the caller's normal interrupt state.

Each native entry requires a task-backed control and checks the current frame
against that task's stack, reserving 4096 bytes before descending into the parser.
The shared parser-stack push/pop helpers also reject overflow and underflow.
This protects the exercised recursive and iterative expression paths; it does not
certify arbitrary callback stack consumption. Providers must respect the task
stack budget.

A root call allocates a separate parser stack and registers it as code-allocation
kind 7. It is released after successful parsing and by full control unwind after
an exception. The optimizer's `cc->ps` remains separate. A recursive supplied stack
must already be registered to the same control; arbitrary caller buffers are
rejected. Nonempty source bodies, symbols, generated code and other callback
allocations have their own lifetimes; owning the parser stack does not establish
ownership for them.

The native probe uses [owned token reading](i386-parser-token.md) and provides
diagnostic, IR insertion and recursive-expression
callbacks and intentionally fails on callbacks outside its arithmetic coverage.
It parses arithmetic source, runs the production optimizer/backend and executes
the resulting bytes before releasing the control. This is a test environment,
not a replacement grammar or a general native adapter. Declaration/type parsing,
full statement execution and durable code/data publication remain required.

Validation executes eight arithmetic programs and four failure cases on each of
the boot and worker tasks. The failure cases cover malformed input, exhausted heap,
deep parentheses and excessive unary operators, with exact resource restoration.
The standalone suite also checks instruction compatibility, module rejection and
VGA/input behavior. Its current guest uses an emulated 486 with 8 MiB; this does not
satisfy strict 386SX/DX acceptance. At the ABI 23 expression milestone, the retained compiler image was 739096 bytes
(739112 heap bytes), and the kernel is 389432 bytes.
