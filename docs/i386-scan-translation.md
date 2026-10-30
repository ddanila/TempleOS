# Public scan-code translation

The native console now publishes `Char2ScanCode`, `ScanCode2Char` and
`ScanCode2KeyName`. Their original bodies are shared through
`Kernel/SerialDev/KeyScanTranslateCore.HC` and `KeyScanNameCore.HC`; native
code supplies equivalent 80-entry normal, shift and control decode tables.
This does not replace the existing hardware keyboard event path.

The differential fixture builds a byte-for-byte table of 256 scan codes and
256 character inputs under ten modifier combinations, including exact returned
key names. The pinned original, the original rebuilt with the extracted code,
and native output have the same SHA-256 and no differing bytes
(`build/i386-public-scan-translation-original-v1`,
`build/i386-public-scan-translation-rebuilt-original-v1`,
`build/i386-public-scan-translation-native-v2`; runner
`tools/test-i386-public-scan-translation.py`). The old native image rejects
the missing conversion binding (`build/i386-public-scan-translation-native-red`).
The comparison covers these input ranges, not hardware event delivery, arbitrary
integer inputs, key descriptions or the full key-map UI.

Both original bootstrap generations and the 386 cross-build/audit pass
(`build/public-scan-translation-rebuild-v1.log`,
`build/i386-public-scan-translation-cross-v1`). An 8 MiB ordinary-include and
drive-fields smoke check also passes with unchanged inputs
(`build/i386-public-scan-translation-smoke-8m`); it is not a startup-timing
or full minimal-profile gate. C1–C5 remain open.
