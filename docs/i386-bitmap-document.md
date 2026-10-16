# Bitmap sprites in documents

ConsoleRuntime 129 integrates the complete original `DC2Sprite` and `DocSprite`
bodies through shared source cores. The original x64 call sites include the same
cores. Both bodies match the pre-extraction source byte-for-byte. Public native
bindings are appended to the retained console export table, preserving existing
indices and the data-symbol mask.

This implements prerequisites for the graphics branch of original `DocType`.
The GR reader/decompressor, full `DocType`, original terminal startup, and full
desktop/application qualification remain open.

The common fixture tests widths 1, 8, 9 and 17 at multiple heights, fills every
padded bitmap byte with a deterministic pattern, and exports all four sprites.
The host independently constructs each packed bitmap record (type, coordinates,
width, height, padded body and end record) and compares every byte. Guest checks
cover document-owned copies, source-buffer mutation, binary-entry numbering,
reference counts, tagged custom formatting, default put-document selection and
absence of a put document. All six checks must pass (mask 63).

Pinned-original and shared-source controls pass with unchanged input hashes:

- `build/i386-c2-bitmap-document-bytes-reference/result.json`
- `build/i386-c2-bitmap-document-bytes-shared/result.json`

Bootstrap and cross-build pass with all 1516 source and 24 build inputs
unchanged (`build/i386-c2-bitmap-document-cross/input-audit.json`). The native three-command suite passes all six checks and four exact buffers
with unchanged inputs in `build/i386-c2-bitmap-document-bytes-native`. The isolated
8 MiB gate passes all nine checks in 56.453438 seconds with no build-provider
load on committed 406db5e9. Its four execution pins match the committed source
snapshot; 16 MiB diagnostics are still running.

The unchanged old native image rejects the corrected global-vector fixture at
DC2Sprite in `build/i386-c2-bitmap-document-binding-red` with execution inputs
unchanged. Its exact fixture and runner are archived alongside the result.
The first Console-129 run compiled past the new bindings but stopped at the
fixture's unavailable public MemCmp call. The final fixture uses an explicit
byte equality loop for the same comparison; both original controls were rerun
and pass. Public MemCmp remains an API gap, separate from the sprite routines.

The first fixture used unsupported local-array initializers and assumed binary
numbering began at zero. The corrected fixture uses global vectors and verifies
original numbering from one. Those preliminary runs are retained under
`build/i386-c2-bitmap-document-reference` and
`build/i386-c2-bitmap-document-native-red`; their execution inputs changed during
fixture correction, so they are not qualified native regression evidence.

```sh
python3 tools/test-i386-bitmap-document.py --out ORIGINAL
python3 tools/test-i386-bitmap-document.py --shared --out SHARED
python3 tools/test-i386-bitmap-document.py IMAGE --out NATIVE
```

These checks cover conversion and insertion, not sprite rendering, GR-file
loading, full file coverage or C1–C5 acceptance. All inventory entries remain
unqualified.
