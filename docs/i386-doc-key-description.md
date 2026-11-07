# Printable DocPutKey description queries

Original DocPutKey handles printable SCF_KEY_DESC queries by formatting a
Char2KeyName description and returning without editing. Native dispatch has
explicit clipboard/autocomplete description branches, but its general
printable metadata path falls through to DocBasicEditCore. This can replace
selected text during a description query. The existing console-level metadata
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

Restoring the original printable metadata branch is the next implementation
step. This test does not qualify the complete key-description map, KeyMap UI,
editor code-tools/sprite workflows or all DocPutKey behavior. C1–C5 remain open.
