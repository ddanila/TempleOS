# Public absolute directory paths

The native `DirNameAbs` now delegates to the existing shared directory path
normalizer through the current task's borrowed file context. FileRuntime 64
adds an owned directory-path callback; ConsoleRuntime 195 copies the result to
the calling task's public heap and releases the provider allocation. Null
input is treated as an empty string, as in the original wrapper. The callback
restores the borrowed task-file state and interrupt flags before returning.

The original reference covers null and empty input, relative components,
absolute paths, parent traversal, explicit drive paths, restoration of the
caller's directory and caller-heap recovery. It passes mask 255 with unchanged
inputs (`build/i386-dir-name-abs-original-v2`). The preceding native image
rejects the missing binding before the fixture runs
(`build/i386-dir-name-abs-native-red`). Both original rebuild generations pass
(`build/i386-dir-name-abs-rebuild.log`), and the native cross-build and 386
instruction audit pass (`build/i386-dir-name-abs-cross`). The original rebuild
is not a reproducibility pass. Cross-task use, invalid drives, injected
allocation failures and all path edge cases remain unqualified.
The 64 MiB native fixture passes the same eight checks with unchanged inputs
and a byte-identical delivered fixture (`build/i386-dir-name-abs-native-v1`).
The concurrent run does not qualify startup timing.
The 8 MiB initial welcome-screen pixel check also passes with unchanged inputs
(`build/i386-dir-name-abs-welcome-8m`); it is not the full minimal-profile or
startup timing gate.
