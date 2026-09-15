# Native source input lifecycle

CompilerRuntime ABI 35 (200 bytes) adds `input`, a synchronous source-buffer
entry for the console and other native callers. `CI386CommandInput`
borrows the source, filename, file/include services, type descriptors and callback
context for the duration of the call. It uses the current task's symbol scope and
preserves the caller's active compiler-control boundary and IR.

The entry creates and enters a private control, parses each top-level command,
executes its generated output and reports each non-U0 result through `answer`.
The callback receives raw result bits and a borrowed value-class descriptor.
Pointer depth is essential: `RT_PTR` and `RT_I64` both equal 10. F64 bits must not
be converted as an integer. Pointer results are not automatically dereferenced or
formatted. A callback must consume or copy borrowed data synchronously. The
entry has no fixed command-count limit; frontend resource/stack limits still
apply. An empty input is valid.

`CCF_JUST_LOAD` is the only accepted caller flag. It skips executable commands
and answer callbacks while retaining the shared parser's declaration and static
initialization behavior. The entry supplies its own input-buffer ownership flags.
Invalid arguments or flags return false before creating a control.

Frontend diagnostics are forwarded synchronously with their control, severity and
message, before error/warning accounting. Parenthesis-warning requests obey the
existing option/define suppression policy and receive the standard message. Lexer failures can instead
supply only the recorded exception and error count. The input record reports
completed commands, attempted answer deliveries, compiler errors/warnings and the
caught exception. A false return without an exception can indicate initialization,
publication or teardown rejection.

After successful parsing/execution, transient IR is discarded, including retired
optimizer nodes after saved command views have gone. Publication then transfers
completed definitions, code and literal/static storage to the task. Unwinding the
private control releases all remaining temporary state. Compiler and allocation
exceptions return false after cleanup. Other exceptions, including callback
exceptions (including code zero), are rethrown after cleanup so the surrounding task policy handles
them. Input and callback storage must remain live through that cleanup.

Publication of frontend classes/functions/globals is per submitted buffer.
Preprocessor defines use the task define table immediately and can persist after
a later failure. A later failed buffer preserves definitions
from earlier successful buffers. Execution is not transactional: assignments and
other side effects before a later failure remain. In particular, user code must
not retain references to unpublished private data across failure. Collisions are
rejected; definition replacement and dependency-aware unloading remain pending.
See [program publication](i386-program-publication.md) for storage ownership.

The retained [VGA console](i386-console-runtime.md) now submits keyboard lines to
this service and renders results/diagnostics. It also executes disk-backed startup
source in the same scope before accepting keyboard input. Multiline source editing, the full
public TempleOS interfaces and complete language/document workflows remain open.
The console implementation lives outside the fixed boot reservation.

## Verification

The standalone probe exercises this entry during boot and from a worker, with an
outer active control and IR sentinel. Cases cover integer and software F64
results, synchronous literal inspection, multiple results before malformed input,
load-only execution suppression, callback exception propagation, failed private
definitions, invalid flags and published functions with pointers to global data.
Fresh inputs reuse published definitions after a failed input. Fixture-owned
published symbols/storage are removed afterward, and the suite checks complete
heap, control, reference and exception recovery.

Run `python3 tools/test-rebuild.py` followed by
`python3 tools/build-i386-kernel.py --test`. QEMU/486 development checks do not
establish strict 386SX/DX or physical-machine compatibility.
