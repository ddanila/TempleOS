# Task frame pointers

The original `HashGenericAdd`, `FramePtr`, `FramePtrAdd`, `FramePtrSet` and
`FramePtrDel` bodies are shared with the native runtime and exposed through the
public hash interface. Native deletion uses the existing task hash removal
provider. The 64-bit exchange preserves interrupt state while operating on the
single supported CPU; this does not establish multiprocessor atomicity.

The shared fixture checks missing entries, creation and lookup, 64-bit exchange,
deletion, generic hash payloads, a separate live task's table, and retrieving
and freeing an owned frame from a task-end callback. It returns mask 255 on the
pinned original, rebuilt original and native 64 MiB image with unchanged inputs
(`build/i386-frameptr-reference-v2`, `build/i386-frameptr-rebuilt-v3`,
`build/i386-frameptr-native-v3`). The original two-generation rebuild, native
cross-build and 386 audit pass (`build/i386-frameptr-rebuild-v2.log`,
`build/i386-frameptr-cross-v2`). The first cross-build rejected unsupported
`#undef` directives in the adapter (`build/i386-frameptr-cross-v1`); the final
source avoids those directives. Allocation failures, concurrent mutation and
all task-retirement paths remain outside this fixture.

This service is a dependency of the original asynchronous `Noise` sound-effect
task and its end callback. `Noise`, KeepAway gameplay and C1–C5 remain open;
the previous unchanged KeepAway load still stops at `Noise` on line 487.
