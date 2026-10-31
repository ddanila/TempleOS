# Editor link rejection and exception unwinding

Native `Ed` previously left its `try` block through early `goto` exits when an
editor link was rejected. A later caller exception could then stop the kernel
with `BAD PUBLIC MEMORY`. The editor now completes the exception scope normally
before returning, while freeing the converted link strings. At that earlier
revision, native still rejected valid `BF:` links.

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
passed these cases and also checked the then-unsupported valid `BF:` case,
where conversion allocates both strings
(`build/i386-editor-reject-unwind-native-v2`; runner
`tools/test-i386-editor-reject-unwind.py`). The earlier native-only Bible check expected rejection; it has since been
changed to check a missing verse after Bible link support was added. The
revised contract passes on the 400-line Bible sample image
(`build/i386-doc-bible-unwind-regression-v1`).

Both original bootstrap generations, the native cross-build and 386 audit, a
supported `MN:` editor regression and an 8 MiB smoke check pass
(`build/editor-reject-unwind-rebuild-v1.log`,
`build/i386-editor-reject-unwind-cross-v1`,
`build/i386-editor-reject-symbol-regression-v1`,
`build/i386-editor-reject-unwind-smoke-8m`). These bounded checks do not qualify
all editor errors, exception paths, Bible editing, or desktop behavior.
