# Retained native statement and function compilation

CompilerRuntime ABI 32 (188 bytes) appends `statement` to the retained compiler
interface. Callers create an active control, obtain its `frontend` services, read
the first token and repeatedly invoke `statement` until EOF. This entry parses
private JIT declarations through the complete shared statement, function, global
and initializer cores. It temporarily clears the bootstrap AOT flag and restores
it after a successful statement. Parse or generation errors require control unwind.

The same environment now handles function bodies, local declarations, control
flow, global/static storage, string-pointer and aggregate initialization. Generated output
and private symbols belong to the originating compiler control. They remain valid
while that control is alive, or until publication transfers them to the task.
The retained console uses these services through its command-input entry.

## Calls and output ownership

The output builder saves the caller's compilation context, emits into a temporary
buffer and copies code and literal data into registered final storage. Named calls
use private descriptor copies with independent relocation lists. Both call-start
and call-end nodes refer to the same copy. Relative call operands are patched only
after final allocation; recursive calls target the new function's entry address.
Existing task symbols are not modified to hold temporary fixups.

Completed private functions may call one another, pass defaults, recurse and use
function pointers. Unresolved extern/forward calls still fail explicitly. Generated
software-F64 calls borrow the retained runtime's lifetime. All generated functions,
their callees and referenced private data must remain live during execution.
ABI 34 adds publication into the current task's scope; see
[program publication](i386-program-publication.md). General unresolved module
linking and definition replacement/unload rules remain open.

## Failure boundaries

Every recursive shared statement entry invokes an optional stack-check callback;
the native implementation checks current-task ownership and remaining stack space.
The x86-64 adapter leaves this callback null. Undefined goto labels fail before
generation. Compiler-time expressions reject automatic-frame references because
their temporary execution frame does not contain the function's runtime locals.

Automatic register hints are accepted; explicit x86-64 register assignments fail.
Private static allocation is zero-filled. ABI 33 adds a top-level command compiler
using the existing output executor; see [native commands](i386-native-commands.md).
Assembly/stream/try service integration, trace disassembly, symbolic stored pointers
and deferred AOT executable initializer output remain unfinished.
These limitations do not change the complete language and self-hosting requirements in `PLAN.md`.

## Bootstrap constant evaluation

The cross-compiler's host integer evaluator now runs the shared folding pass twice,
as the native backend already does. The first pass resolves temporary operand-size
operations introduced by addition/subtraction; the second folds the resulting
integer expression. Only a validated folded integer is emitted as host x86-64
return code. This does not execute i386 instructions on the compiler host.

## Verification

`CompilerStatementProbe.HC` compiles and executes functions during boot and from
the worker task. Its cases cover loops, switch ranges, goto, defaults, recursion,
nested calls, F64 conversion, global arrays, static state, aggregate fields,
indirect calls and variadics. String cases cover four-byte pointer stores, adjacent
scalar fields, writable/empty/concatenated/embedded-NUL strings, static pointers,
aggregate members and inferred pointer arrays. Negative cases cover invalid declarations, unresolved
calls and labels, failed input after allocating string storage, unsupported
register assignments, excessive
statement nesting and runtime-local references in static initialization. Every
case requires exact restoration of heap bytes/allocation counts, task references,
active controls, exception state and interrupt state after unwind.

The function corpus also exercises arithmetic in switch labels, array bounds and
default arguments through the cross-compiler's host constant evaluator.

Run the x86-64 bootstrap rebuild first, then the standalone integration and
function/data checks:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
python3 tools/test-i386.py --functions
python3 tools/test-i386.py --data
```

QEMU/486 development tests do not establish strict 386SX/DX or physical-machine
acceptance. The complete document workflow and native self-hosting remain required.
