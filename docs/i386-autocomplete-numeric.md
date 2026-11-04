# Numeric dictionary completion

The rebuilt original and native normal image pass all ten Ctrl+digit dictionary
slots using real keyboard input. The prefix Appl selects Applaud, Applauder, Applausable,
Applause, Applausive, Apple, Apple pie, Apple-faced, Apple-jack and Apple-john.
The host independently scans the pinned 95,293-word asset for the first matching
word and its ten contiguous neighbors. It does not reproduce ACDWordPtAt's
binary-search implementation or use application output as the expected list.

The workflow initializes the unchanged library and its full dictionary through
normal AdamFile/ACInit calls. An observer captures the actual acd.fillins slots,
widget document and geometry, and the completed input line. The host types
ACNCheck("Appl, presses a physical Ctrl+digit and keeps Ctrl held until completion
arrives, then closes and submits the expression. The test function records its
actual string argument and execution counter and returns 42. Every input and
executed argument must equal the asset-derived choice, and counts must advance
exactly from one through ten. The observer never invokes ACDFillin or In.

The native console needed an additional metadata filter. ACTask builds its Ctrl
panel by posting SCF_KEY_DESC KeyMap queries to the focused task. These describe
keys, including printable characters and Enter; they must not edit or submit
input. Before the fix, an explicit printable query changed 6*7 into A6*7 and
failed compilation (`build/i386-autocomplete-console-description-before-v1`).
The loaded-library baseline also completed Applaud but appended/submitted query
characters (`build/i386-autocomplete-numeric-native-before-v1`). Both failures
have unchanged-input records. The console now filters metadata before its input
actions while answering retained autocomplete descriptions through DocPutKey.
The complete key-description map remains unqualified.

The cold regression passes on `build/i386-autocomplete-numeric-cross-v1/kernel.img`
(`build/i386-autocomplete-console-description-after-v1/result.json`). It asserts
that AutoComplete is absent, sends the printable description query, then submits
exactly 6*7 through actual keyboard input and checks the visible 42. The existing
editor metadata, autocomplete release-order, text-retention and subsequent plain
F1 Help checks also pass. The final offline filesystem audit passes.

Observer and capture requirements are explicit:

- Original DocScanLine includes the terminal drive prompt. The observer extracts
  the command after that prompt and compares the complete remaining input.
- Export records are parsed only after their terminating newline. An original
  attempt caught a partially written E9 line; the shared collector now waits
  for the complete record and still rejects malformed complete records.
- Observer-owned report buffers remain alive until the captured command is
  submitted, so task retirement cannot invalidate a pending memory export.
- Current-word and dictionary pointers can survive while ACTask builds its Ctrl
  panel. Native v1 completed slot zero, then correctly failed the widget oracle
  on an empty transitional document at slot one. Readiness now requires the
  normal Word:Appl document, unchanged together with geometry across a completed
  WinMgr frame after the application's refresh sleep. Exact comparisons remain.
- A historical 42 can appear before a new result has drawn. Reference v5's first
  pixel audit rejected its case-one capture for that reason. Capture now waits
  for the exact unique submitted command and a 42 font mask immediately below
  it. The separate pixel checker verifies those same per-case artifacts offline.

Final evidence is `build/i386-autocomplete-numeric-reference-v6/result.json`
and `build/i386-autocomplete-numeric-native-v2/result.json`, with passing
pixel-audit.json records in both directories. Every widget document and its
geometry match exactly, and all ten viewport crops match in every pixel:
197,120 pixels total. Each crop is columns 51-78, rows 13-23 (224 by 88 pixels).
The case-specific submitted command and adjacent 42 pass the independent pixel
audit too. On native, all thirty persisted prefix, selected-input and executed-
argument reports equal their guest-memory exports; the final offline filesystem
extent/bitmap audit passes. All final run and pixel-audit inputs remain unchanged.
Source, harness, oracle and fixture snapshots and input digests accompany runs.
The native profile is normal startup, 64 MiB, KVM, 486,-fpu and live WinMgr.

Two original rebuild generations pass (`build/autocomplete-numeric-rebuild-v1.log`),
as do the 386 instruction audit and all 1,261 delivered-source checks. The
separate 8 MiB normal startup smoke passes in 42.16 seconds, under its 60-second
budget, with live WinMgr/welcome, arithmetic, public input state/timing and exact
framebuffer checkpoints (`build/i386-autocomplete-numeric-minimal8-v1`). It is
not the full minimal regression suite, and it does not load the full dictionary.

This workflow does not qualify numeric input in the custom editor, definition
popups, other prefixes, invalid/unavailable slots, exact application heap
recovery, complete key descriptions, minimum RAM for the dictionary, complete
minimal regressions or C1-C5. The result-pixel check covers each command and its
adjacent 42, not full terminal formatting; the original and native answer formats
can differ. The previous [source completion](i386-autocomplete-interaction.md)
and [editor](i386-autocomplete-editor.md) records retain their own image scope.

With the qualified original rebuild and word archive available, use fresh paths:

```sh
python3 tools/test-i386-autocomplete-numeric.py --out build/ac-numeric-original
python3 tools/check-i386-autocomplete-numeric-pixels.py build/ac-numeric-original --out build/ac-numeric-original/pixel-audit.json
python3 tools/test-i386-autocomplete-numeric.py build/i386-autocomplete-numeric-cross-v1/kernel.img --reference build/ac-numeric-original --out build/ac-numeric-native
python3 tools/check-i386-autocomplete-numeric-pixels.py build/ac-numeric-native --out build/ac-numeric-native/pixel-audit.json
python3 tools/test-i386-autocomplete-cold-keys.py build/i386-autocomplete-numeric-cross-v1/kernel.img --out build/ac-numeric-cold
```
