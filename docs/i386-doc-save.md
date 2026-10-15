# Complete original entry/document serialization

Console 104 uses the complete original Doc2PlainText and DocSave bodies, shared
through DocPlainTextCore.HC and DocSaveCore.HC. Public DocSave replaces its
previous native record-subset implementation; Doc2PlainText adds a public export,
bringing console exports to 256. Public layouts, Memory 26 and private console
services are unchanged. The retained record serializer remains available to
existing component probes; it is not the public DocSave implementation.

The serializer preserves canonical command/flag spelling, formatted arguments,
quoted strings, color names, plain/doubled-dollar modes, cursor markers, CRLF,
data-entry filtering and binary records. Original `%$Q` encodes a literal dollar
as `\d`. Raw-type names are shared from the original compiler initialization via
RAW_TYPE_NAMES_LIST; native startup loads ST_RAW_TYPES if absent. The public
document header includes the canonical RT_* declarations. This metadata
does not add implementation of the fictitious/unimplemented F32/UF types.

## Contracts

The paired runners share `tests/guest/i386-doc-save-reference/DocSave.HC`.
Eight entry cases require exact canonical strings (mask 31): numeric/named
foreground, button values, quote/backslash/dollar escaping, link, macro, a high
flag with user data, and a bound U32 data field. They also require unchanged entry
fields, incoming lock, caller role and exact heap recovery.

Ten document cases require mask 63: text, plain dollars, doubled dollars,
menu entry, named color, cursor position, binary record, incoming lock, CRLF and
bound-data filtering.
Their expected serialized bytes are constructed independently, including a known
16-byte binary header and five payload bytes. Tests compare size and every byte,
then load through DocLoad and check expected text. Cursor/lock/caller state and
exact heap recovery must hold. A serializer/loader pair with matching corruption
cannot pass the independent byte oracle.

The old Console 103 image rejects the Doc2PlainText API prerequisite. The native
runner stages the fixture additively on a writable image copy and checks exact
readback and immutable tool/image inputs. The retained editor's real keyboard
undo suite is included because original DocSave's cursor-marker insertion/removal
must remain compatible with live editor state.

## Boundaries

Complete source presence does not qualify every flag combination, complex binary
reference graph, callbacks, failure/cancellation/Exit, peak memory or malformed
entry handling. These remain explicit C4 gates. DocRead and the retained editor's
restore path still use their existing record loader; this checkpoint does not
claim complete reader/writer or original editor interchange for every newly
serializable entry. Full reader integration needs its own file/flag/error tests.

Original undo still needs a 386-compatible clock with explicit frequency policy
and qualification of the complete original capture/restore path. The retained
editor's undo is regression coverage, not original undo acceptance. Full DocPutKey
and actual chooser input remain open. See PLAN.md for accepted run evidence.

## Accepted evidence

`build/i386-c4-doc-save-filter-reference` and
`build/i386-c2-doc-save-types-contract` pass eight masks of 31 and ten masks of 63.
Native passes 21 commands with exact fixture readback and unchanged inputs;
original inputs are unchanged too. The original two-generation bootstrap and
`build/i386-c2-doc-save-types-cross` pass, including the limited 386 audit. All
1487 source/build hashes match. Loading, clipboard, character/form primitives and
the retained editor's keyboard-driven undo pass on the final image. Normal
8 MiB startup passes nine checks in 54.73 seconds. These do not close C1–C5.
