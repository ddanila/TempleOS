# Autocomplete in the native editor

The normal 64 MiB native image now routes autocomplete key-downs through the
retained DocPutKey actions. Function-key releases belonging to a completion are
consumed even when Ctrl is released before the function key. Later ordinary
function keys keep their existing editor behavior.

The original editor and native custom editor both pass the real project-file
Ctrl+F1 workflow. The unchanged library initializes all 95,293 dictionary words;
the independent project/word-list oracle checks eleven source words and the five
exact suggestion names, hit counts and order. Actual keyboard input completes
ACUI to ACUIAlpha through ACFillIn, In, the real input-filter task and public key
messages. Both exported editor documents are exactly `ACUIAlpha;` followed by
the saved cursor byte 05. Native Ctrl+S persists those same eleven bytes to
C:/ACUIEdited.HC. Offline extraction checks the saved file after QEMU exits, and
the final extent/bitmap audit passes. No completion function is invoked directly
by the observer or host.

Evidence:

- Original: `build/i386-autocomplete-editor-reference-v4/result.json`.
- Native: `build/i386-autocomplete-editor-native-v3/result.json`.
- Image: `build/i386-autocomplete-editor-cross-v3/kernel.img`.
- Rebuild: `build/autocomplete-editor-rebuild-v3.log` (two generations pass).
- Delivered source: `build/i386-autocomplete-editor-cross-v3/source-audit.json`
  (all 1,261 files pass); the build's 386 instruction audit also passes.

The cold-library regression also passes on this image:
`build/i386-autocomplete-editor-cold-after-v4/result.json`. It asserts the real
AutoComplete symbol is absent, runs the existing console source/42-pixel check,
and queues synthetic Escape and printable description queries before DocEd.
Neither query exits or edits. Real Ctrl+F1 (both release orders), Ctrl+F4,
Ctrl+F5 and Ctrl+1 preserve the editor source exactly; a subsequent plain F1
still opens Help, and both editor exits use actual Escape. The final filesystem
audit passes and all archived harness inputs remain unchanged. Cold v3 stopped
on the fixture's unavailable SC_ESC macro; v4 uses its numeric scan value 1.
Cold-before-v1 reproduced the prior image opening Help on Ctrl+F1 and timed out
waiting for an editor return. Cold-after-v1/v2 passed the earlier bounded cases
before the explicit synthetic-query checks were added.

The native run uses KVM and `486,-fpu`, normal startup, live WinMgr and actual
AdamFile loading. Harness, project and fixture snapshots and input digests are
archived alongside the results. All run inputs remained unchanged. Host
keys.jsonl records each key transition and the contemporaneous debug-log size.
The editor exit trace identifies the actual character and scan flags.

An additional failure appeared after routing completion: ACTask's Ctrl-key
panel sends KeyMap queries with SCF_KEY_DESC. Its synthetic Escape has scan flags
0x80000401. The original DocGetKey filters description queries before returning
an editing key. The custom editor instead treated that query as Escape, then
processed subsequent queries as console input. Native attempts v1/v2 completed
the symbol but failed the save workflow. The v2 exit trace and host key trace
prove that no host Escape preceded this exit. The editor now separates these
metadata queries before any input action or function-release tracking. It
answers retained autocomplete descriptions through DocPutKey; other description
queries do not edit, execute, save or exit. This does not qualify the complete
key-description map.

The initial editor observer was armed while typing ACUIEdit at the shell, which
could momentarily expose the target prefix. It is now armed inside the editor
fixture. Native v1 also exposed a report-buffer race: editor export reused the
observer's shared report while its selected report was still being written.
The editor now exports its own buffer and leaves it alive for collection.
Original references v2-v4 pass with the observer started inside the fixture;
v4 and native v3 use the final fixture and key trace.

Editor/widget geometry and pixels are captured but not compared in this mode.
The custom editor uses its existing VGA renderer. This test does not qualify
its visual equivalence, execution inside the editor, save/reboot/reopen, other
completion indexes, numeric selection, source/definition popups, exact heap
recovery, full key descriptions, minimum-memory regressions or C1-C5. The older
console pixel comparison remains scoped to its separately tested image; see
[i386-autocomplete-interaction.md](i386-autocomplete-interaction.md).

With the qualified rebuild and word archive available, use fresh directories:

```sh
python3 tools/test-i386-autocomplete-interaction.py --editor --out build/ac-editor-original
python3 tools/test-i386-autocomplete-interaction.py build/i386-autocomplete-editor-cross-v3/kernel.img --editor --reference build/ac-editor-original --out build/ac-editor-native
python3 tools/test-i386-autocomplete-cold-keys.py build/i386-autocomplete-editor-cross-v3/kernel.img --out build/ac-editor-cold
```
