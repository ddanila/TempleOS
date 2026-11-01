# Retained compiler call-record pressure (2026-11-01)

The nine-module retained build on the include-dollar image exhausted its
16 MiB arena during `I386FrontendCalls`, after parsing `DocRecalc`. The guest
reported a `0x7E`-byte parser payload request and largest free span `0x48`
(`build/i386-c5-include-dollars-native-build`). No module was completed.
That stage previously created a full function descriptor for every call site,
including repeated calls to the same function. The failure log does not by
itself prove how much of the arena each category occupied.

The native frontend now reuses a call descriptor for the same original function
within one output and uses a separate, depth-sized stack for matching nested
call start/end nodes. Each emitted call retains its own relocation record;
recursive calls, unresolved forward calls and the existing signature checks
remain in the linker path. Compiler services advance from version 75 to 76.

The compiler program probe now compiles and executes repeated nested calls to a
forward declaration and a function with two recursive call sites. It also
requires three separate call relocations to the forward target. The original
two-generation rebuild and full native cross-build pass. The 16 MiB diagnostic
passes both compiler phases, the new cases, retained-code checks and exact VGA
restoration (`build/i386-c5-shared-calls-diag16`).

An isolated 8 MiB run passed all nine functional checks and VGA restoration but
missed the 60-second startup gate at 70.387 seconds
(`build/i386-c5-shared-calls-startup8`). The preceding image, run independently
with the same nine commands, took 70.392 seconds
(`build/i386-c5-shared-calls-control8`). One paired comparison does not establish
a general performance distribution; neither run passes the timing gate.

A new full nine-module retained build is running on the candidate image SHA-256
`4f3d19cca69bf7246ec592d444e29550c279255e3d0fe08d1ec4ed2c7587abf2`
(`build/i386-c5-shared-calls-native-build`), with 16 MiB, TCG `486,-fpu`,
the welcome screen and a 43200-second per-command limit. The previous failed
build remains separate. The running build has not yet established that it can
complete ConsoleRuntime, let alone the full module set or native generations.
