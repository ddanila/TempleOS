# Case-insensitive string comparison

The native console publishes `StrICmp` and `StrNICmp`. The portable
implementation folds ASCII `a`–`z` to uppercase and preserves the original
three-way comparison result; bytes outside that range are compared unchanged.
The bounded version preserves the original zero-limit and negative-limit
behavior for terminated inputs.

The pinned original and native fixtures pass mask 15 with unchanged inputs
(`build/i386-stricmp-original-v1`, `build/i386-stricmp-native-v1`; runner
`tools/test-i386-stricmp.py`). They check all 65,536 first-byte pairs, zero and
one-byte limits, mixed case, prefixes and selected larger and negative limits.
The preceding native image rejects the missing binding
(`build/i386-stricmp-native-red`). Invalid pointers and unterminated strings
are outside this check.

Both bootstrap generations and the 386 cross-build/audit pass
(`build/stricmp-rebuild-v1.log`, `build/i386-stricmp-cross-v1`). C1–C5 remain
open.
An 8 MiB ordinary-include and drive-fields smoke check also passes with
unchanged inputs (`build/i386-stricmp-smoke-8m`); it does not measure the
startup budget or qualify the complete minimal profile.
