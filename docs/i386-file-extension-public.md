# Public filename extension operations

The native public file interface now exposes the shared original `FileExtDot`,
`FileExtRem`, `ExtChg`, `IsDotC`, `IsDotZ` and `ToggleZorNotZ` implementations.
The removal, change and toggle bodies are shared with original `DskStrA.HC`;
no filesystem access is involved. `FileExtDot` is a dependency of the original
terminal right-click handler.

The pinned original and rebuilt original with the shared source both pass a
seven-group contract (mask 127) covering whole-path dot scanning, in-place
removal and return pointers, absent extensions, extension changes, compressed
and contiguous suffix recognition, toggling, and exact caller heap recovery
(`build/i386-file-extension-public-original-v1`,
`build/i386-file-extension-public-shared-original-v1`; runner
`tools/test-i386-file-extension-public.py`). Both original bootstrap
generations and the native cross-build/386 audit pass
(`build/file-extension-public-rebuild-v1.log`,
`build/i386-file-extension-public-cross-v1`).

The native public API passes the same contract with unchanged inputs
(`build/i386-file-extension-public-native-v1`), and the final image passes an
8 MiB ordinary-include and drive-fields smoke check
(`build/i386-file-extension-public-smoke-8m`).

This bounded contract does not cover allocation failures, concurrent mutation,
file I/O or the full terminal right-click handler. C1–C5 remain open.
