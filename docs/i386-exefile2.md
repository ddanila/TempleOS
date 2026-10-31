# Throwing file execution checkpoint

Native ConsoleRuntime 180 exports `ExePutS2` and the original `ExeFile2`
wrapper, shared through `Compiler/ExeFile2Core.HC`. `ExePutS2` uses the
retained compiler entry and its existing control unwind, while requesting
that compiler and break exceptions propagate to its caller. The ordinary
`ExePutS` path retains its existing handling. These APIs are prerequisites for
the original `PopUpFile` wrapper, which is not yet integrated.

The original and native 64 MiB fixtures pass mask 509 with unchanged inputs
(`build/i386-exefile2-original-v3`, `build/i386-exefile2-native-v2`). They
cover successful source execution, a custom runtime exception through source
and through an included file, explicit `Compiler` and `Break` throws, default
and explicit file extensions, and subsequent execution. The native 8 MiB
run passes the earlier subset without the explicit Compiler/Break checks
(`build/i386-exefile2-native-8m-v1`). These concurrent runs do not qualify
startup timing or all compiler flags and failure modes.

The first original fixture used an undefined identifier to provoke a compiler
error; the original guest entered its debugger and timed out rather than
finishing the fixture (`build/i386-exefile2-original-v1`). It was replaced
with explicit thrown exceptions, so malformed-source debugger behavior is not
qualified. The preceding native image rejects the missing `ExePutS2` binding
before executing the fixture (`build/i386-exefile2-native-red-v1`). Both
bootstrap generations, full cross-build and 386 audit pass
(`build/i386-exefile2-rebuild-v1.log`, `build/i386-exefile2-full-cross-v1`),
as do the 16 MiB diagnostic and the earlier non-throwing `ExeFile` comparison
(`build/i386-exefile2-diagnostics-v1`,
`build/i386-exefile2-ordinary-regression-v1`). The ordinary `ExePutS`
exception regression also passes explicit Compiler/Break absorption and
custom-exception propagation (`build/i386-exefile2-puts-exceptions-v1`).
Full terminal, application and
C1–C5 qualification remain open.
