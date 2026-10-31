# Editor link rejection and exception unwinding

Native `Ed` previously left its `try` block through early `goto` exits when an
editor link was rejected. A later caller exception could then stop the kernel
with `BAD PUBLIC MEMORY`. The editor now completes the exception scope normally
before returning, while freeing the converted link strings. This change does not
implement Bible links: native still rejects a valid `BF:` link.

The pinned original opens valid uppercase and lowercase Bible links in bail mode,
rejects a missing book, and restores task document roles
(`build/i386-doc-bible-link-original-v2`; runner
`tools/test-i386-doc-bible-link.py`). The previous native image rejects the first
valid link, then stops after the test throws
(`build/i386-doc-bible-link-native-trace-v1`; QEMU was stopped after the terminal
kernel failure). Direct Bible link conversion and repeated missing-book rejection
pass on both original and native (`build/i386-bible-conversion-original-v1`,
`build/i386-bible-conversion-native-red-v1`,
`build/i386-doc-bible-invalid-original-v1`,
`build/i386-doc-bible-invalid-native-red-v1`). The two native directories named
`red` contain passing results.

The focused unwind contract repeats rejection followed by a caught exception
and checks heap recovery for missing `BF:`, missing `MN:` and unknown `ZZ:` links.
The pinned original passes (`build/i386-editor-reject-unwind-original-v2`),
while the previous native image stops with `BAD PUBLIC MEMORY`
(`build/i386-editor-reject-unwind-native-red-v1`). The updated native image
passes these cases and also checks the currently unsupported valid `BF:` case,
where conversion allocates both strings
(`build/i386-editor-reject-unwind-native-v2`; runner
`tools/test-i386-editor-reject-unwind.py`). The native-only valid Bible check
expects rejection and must change when Bible editing is implemented.

Both original bootstrap generations, the native cross-build and 386 audit, a
supported `MN:` editor regression and an 8 MiB smoke check pass
(`build/editor-reject-unwind-rebuild-v1.log`,
`build/i386-editor-reject-unwind-cross-v1`,
`build/i386-editor-reject-symbol-regression-v1`,
`build/i386-editor-reject-unwind-smoke-8m`). These bounded checks do not qualify
all editor errors, exception paths, Bible editing, or desktop behavior.
