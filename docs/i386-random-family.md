# Original random-number family

The complete original `RandI16`, `RandU16`, `RandI32`, `RandU32`, `RandI64`,
`RandU64`, `Rand` and `Seed` implementations are shared through
`Kernel/RandFamilyCore.HC`. The native console publishes the previously missing
members using the existing task-owned seed and timer provider. The extracted
family is byte-identical to the original bodies; `RandU16` retains its existing
shared source.

A paired fixture starts each generator with four fixed seeds and timer mixing
disabled, recording the return value and full post-call seed. It also checks
`Seed` with a nonzero seed and the deterministic-mode flag. The pinned original
and rebuilt original captures match byte for byte
(`build/i386-rand-family-reference-final` and
`build/i386-rand-family-rebuilt-final-v2`). The native 8 and 64 MiB runs match
the pinned bytes with unchanged inputs
(`build/i386-rand-family-native-8m-v1` and
`build/i386-rand-family-native-64m-v1`). The fixture includes negative signed
16- and 32-bit results and the exact `Rand` floating-point bits. It does not
establish distribution quality, every seed, remote-task seeding, timer entropy
or timer-mode equivalence. The native timer provider uses the existing PIT and
jiffy source because the targeted 386 profile has no timestamp counter; it is
not claimed to reproduce the original x64 timestamp sequence.

Both original rebuild generations and the native cross-build/386 audit pass
(`build/i386-rand-family-rebuild-v2.log`,
`build/i386-rand-family-cross-v2`). The initial original fixture used an
unsupported local array initializer and did not reach its checks; the corrected
fixture is used above. The first cross-build rejected an incompletely
initialized export bitmap; the final source supplies every bitmap word.

The unchanged Vocabulary load now passes its earlier `RandU32` rejection and
stops at `ACDDefGet`, which still needs the original dictionary stream services
(`build/i386-app-vocabulary-rand-v1`). It does not yet run a quiz. See
[application launch review](i386-application-matrix.md) and
[stream dependency](i386-cfile-stream.md). C1–C5 remain open.

The isolated 8 MiB startup run passed all nine functional and exact-VGA
checks, but its 60.692-second startup exceeded the 60-second gate
(`build/i386-rand-family-startup-8m-v1`). The timing gate remains open.
