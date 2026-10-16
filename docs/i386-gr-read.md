# Original graphics-file reading and document insertion

ConsoleRuntime 131 integrates the complete original `ExtDft`, `GRRead` and
`DocGR` bodies through shared source cores. Each body matches its pre-extraction
source byte-for-byte. Native GRRead uses the existing public file reader and the
original DCLoad/ExpandBuf path; DocGR uses original DC2Sprite and DocSprite.
Default extensions use the existing shared filename helpers, including their
whole-path dot scanning behavior.

The three new public bindings are appended at indices 318–320. The export data
mask grows to eleven words, with a zero final word for the new function slot;
existing indices and data-symbol bits remain unchanged.

The common fixture checks eight ExtDft cases, including existing extensions,
dots before directory separators, parent-directory syntax, a trailing dot, empty
filename and empty extension. Six graphics-file checks cover four original GR
records (raw and 7/8-bit compressed bodies, with standard/custom palettes),
explicit/default task ownership, explicit document insertion, default `.GR.Z`
resolution with both filesystem and bitmap compression, default put-document
insertion, and the NULL result for a missing file. Document validation decodes
the packed sprite fields and checks all 512 padded pixel bytes independently
of DC2Sprite/SpriteSize.

Pinned-original and rebuilt-original controls pass all fourteen checks (extension
mask 255, graphics mask 63), with unchanged inputs and identical GR record hashes:

- `build/i386-c2-gr-read-reference/result.json`
- `build/i386-c2-gr-read-rebuilt/result.json`

Bootstrap and cross-build pass with all 1523 source files and 24 build inputs
unchanged in `build/i386-c2-gr-read-cross/input-audit.json`. The native four-command
suite passes all fourteen checks with unchanged inputs in
`build/i386-c2-gr-read-native`. The preceding Console-130 image rejects the
fixture at ExtDft in `build/i386-c2-gr-read-native-red`, also with unchanged
inputs. The isolated 8 MiB gate fails its 60-second startup limit at
61.817467 seconds, while all nine behavior/VGA checks pass with no build-provider
load and unchanged execution pins. This failure is retained in
`build/i386-c2-gr-read-startup`; the gate coordinator resumed C5 and skipped its
dependent diagnostics. Startup performance remains open.

The preceding DCLoad candidate's initial 61.118576-second startup failure and
controlled 58.007704-second pass remain recorded in
[its qualification evidence](i386-dc-load.md). This candidate needs its own
memory gates; a predecessor's pass does not qualify it.

```sh
python3 tools/test-i386-gr-read.py --out ORIGINAL
python3 tools/test-i386-gr-read.py --shared --out REBUILT
python3 tools/test-i386-gr-read.py IMAGE --reference ORIGINAL --out NATIVE
```

Full Type/DocType, raw DocDump timing, original terminal creation/startup,
rendering and whole-file qualification remain open. The missing-file check covers
the return value, not parity of diagnostic text. All inventory entries and C1–C5
remain unqualified.
