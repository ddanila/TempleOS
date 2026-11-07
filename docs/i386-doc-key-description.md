# Printable DocPutKey description queries

Original DocPutKey handles printable SCF_KEY_DESC queries by formatting a
Char2KeyName description and returning without editing. Before this change, native dispatch had explicit clipboard/autocomplete
description branches, but its general printable metadata path fell through
to DocBasicEditCore and could replace selected text during a description query. The existing console-level metadata
filter does not qualify the public document routine.

The fixture asks for uppercase, lowercase, digit, dollar, space, tab, enter
and shift-space descriptions, followed by a Ctrl-C description control. It
starts each case with selected Keep text, uses DOCF_DONT_SWAP_OUT to separate
metadata from scheduling, and checks exact description strings, unchanged
text/cursor/selection, lock state, caller roles and caller heap restoration.

Build i386-doc-key-description-original-v2 passes all nine masks of 127.
Native-baseline-v2 (after yield restoration) and before-yield-v1 both fail
with [112,112,112,112,112,114,114,115,127]. The original text/cursor/selection
and description checks fail in the printable cases while the existing copy
metadata control passes. Caller heap, roles and unlocked state pass throughout.
Both native exported mask files are identical, so the failure predates the
yield change. Terminal audits independently reverify all input hashes.

V1 did not test behavior: an unescaped dollar broke HolyC source parsing.
The native compiler rejected the fixture and the original showed its parser
debug prompt. Both frozen inputs and final screenshots are preserved. V2 uses
character code 36 and doubled source-dollar escaping; assertions are unchanged.

The native dispatcher now handles printable metadata before editing, using
Char2KeyName(ch,FALSE), the original description format and Free. The existing
Char2KeyName declaration precedes DocumentRuntime inclusion. Callback, undo,
lock and cooperative-yield behavior is retained; the public ABI stays at
Console 234.

The expanded fixture also checks ordinary insertion into unselected Keep text:
uppercase A with Shift produces AKeep, and lowercase z produces zKeep. Each
control checks exact text, no selection, a live cursor, unchanged description,
unlocked return, caller roles and exact caller-heap recovery. V4 passes on the
pinned original with nine metadata masks127 and two control masks127.

The initial added controls (original-v3/native-baseline-v3) incorrectly assumed
that typing replaces a manually selected entry on both systems. Original
returns masks124, while native returns127. This is a separate observed text/
selection mismatch, still unresolved. The original output buffer was also
uninitialized and only assigned for one-character output, so its exported
bytes do not establish the actual original text. Those frozen fixtures and
terminal audits are retained. V4 explicitly initializes the output buffer and
uses unselected insertion for the regression control; it does not qualify or
waive selected-text editing compatibility. A [separate four-case oracle](i386-doc-selected-typing.md) now captures the exact original text and confirms the native failure.

This test does not qualify the complete key-description map, KeyMap UI,
editor code-tools/sprite workflows or all DocPutKey behavior. C1–C5 remain open.

Native `i386-doc-key-description-native-v1` passes the same eleven cases and
exports all three buffers byte-for-byte equal to original-v4. Fresh arithmetic,
filesystem allocation integrity and input hashes pass. Independent terminal
audits also confirm exact original exports for the nineteen-case clipboard
regression (`i386-clipboard-keys-description-v1`, zero caller/root heap deltas)
and five-case scheduling regression (`i386-doc-key-yield-description-v1`,
samples [1,0,0,1,1]).

Both bootstrap generations pass in `rebuild-doc-key-description-v1-verified`.
The cross-build `i386-doc-key-description-cross-v1` passes the 386 instruction
audit (96 BIOS and 332 protected-mode instructions), and its post-export audit
verifies all 1737 current production source hashes against the bootstrap inputs.
This bootstrap is the existing x64 bootstrap gate, not C5's two installed native
release generations.

The 8 MiB normal startup (`welcome8`) and 16 MiB full diagnostic startup
(`diagnostic16-v2`) both pass the exact 307200-pixel welcome comparison.
The diagnostic terminal audit checks program-probe completion in phases0/1,
code-heap ownership [0,1]/[1,0], file-break cleanup in phases0/1 and startup DONE.
The first diagnostic attempt reached its 300-second limit before second-phase
completion; that incomplete run is preserved as `diagnostic16`. The repeat
uses a 600-second timeout with unchanged assertions. These concurrent runs
establish functional startup, not the isolated 60-second timing gate or full
interactive desktop qualification.
