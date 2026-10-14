# HolyC compile-time stream compatibility

Native TimeClock loading exposes a compiler service gap before its application
logic runs. Its original Load script executes `Cd(__DIR__);;`. In the original
compiler, `__DIR__` expands to `#exe{StreamDir;}`; StreamDir prints a quoted
source-directory name into the compilation stream. Preserve this mechanism
rather than substituting a hard-coded path for one application.

## Failing tests and current coverage

`tools/test-i386-timeclock-native.py` checks source availability, includes the
original Load script and checks subsequent arithmetic on a disposable 64 MiB
native image. The unpackaged input fails with FileFind returning zero on VGA.
After additive packaging, source lookup passes and compilation rejects
`__DIR__` at line 3 of `C:/Apps/TimeClock/Load.HC`. The failed application load
is preserved in `build/i386-c1-timeclock-native-load-red/result.json` and its
guest log. The original sources match the recovered reference byte for byte.

`tools/test-i386-stream-block.py` isolates the compiler requirement. It defines
a counter, changes it through `#exe`, verifies exactly-once execution, injects
a generated function through StreamPrint, checks expression-context injection
and verifies the counter again. The baseline fails at the first `#exe` before
StreamPrint is reached (`build/i386-c1-stream-block-red/result.json`). Both
tests detect complete guest rejection lines as well as VGA results. They do not
yet qualify nested includes, OutMem, cancellation or AOT behavior.

## Implementation path

The original lexer calls PrsStreamBlk, and the extracted shared implementation
is already in `Compiler/PrsStatementCore.HC`. It saves the active code and hash
context, executes the block with CCF_EXE_BLK, restores the parent context and
pushes the generated text back into the lexer. The native frontend's
execute_line/include service hooks currently reject their calls; the lexer
also has no KW_EXE dispatch. Native public headers do not expose the original
StreamPrint/StreamDir services or source-context macros.

Complete these boundaries using the existing shared parser:

1. Dispatch KW_EXE to the shared stream-block parser with the ordinary native
   statement services. Reuse native command compilation/execution; preserve
   the enclosing expression/function IR, symbol scope and flags.
2. Implement source injection with explicit control ownership. A copied lexer
   buffer and its original parser temporary each need exactly one release;
   allocation failure and unwind must preserve that ownership.
3. Expose StreamPrint and StreamDir through versioned native bindings, and
   publish the original source-context macro definitions. Formatting must
   append to the innermost active block, and source directories must come from
   the actual include context, including macro expansion.
4. Add original-vs-native tests for generated definitions, nested blocks and
   nested includes, macro-defined directory use, restored outer context,
   compiler errors, OutMem, cancellation and repeated reclamation. Include
   native module/AOT compilation so the feature is not console-only.
5. Re-run the unchanged TimeClock Load test, then its storage/report oracle
   and interactive/reboot workflows. New dependency failures stay explicit;
   loading alone does not qualify the application.

This is ongoing C1/C4 dependency work. No native stream-block or complete
TimeClock compatibility pass is claimed.
