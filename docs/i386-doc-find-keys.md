# Find-key dispatch

The public native DocPutKey dispatcher now handles F3 and Shift-F3 using the
original EdFindNext service. Before searching it sets scan_fwd from Shift;
metadata returns Edit/Find Next or Edit/Find Last without changing search state.
Alt suppresses this branch, while Ctrl-F3 remains on the autocomplete route.
The retained zero-flag VGA editor still has its own search state and handler;
this change does not complete that editor's migration.

## Direct comparison

`tools/test-i386-doc-find-keys.py` runs ten action and six metadata cases from
`tests/guest/i386-doc-find-keys/Contract.HC`. It deliberately initializes search
direction opposite to the requested action, so a no-match result still checks
that direction was updated. The action cases cover ordinary forward search,
case-insensitive whole labels, case-sensitive whole labels, backward search,
no match, selected-only search, filtered entries, an incoming lock, and two Alt
suppression cases. Metadata additionally covers the Ctrl-F3 autocomplete route.

Every case checks cursor entry/column, the complete CEdFindText record, first
and last text tags, lock ownership, caller put/display/border roles, description,
and exact caller-data-heap recovery. Actual cursor/direction triples are exported
separately. DONT_SWAP_OUT isolates API observations from scheduling; this is not
a full memory-pressure or scheduler qualification.

The pinned original `build/i386-doc-find-keys-original-v1` passes all sixteen
masks 127. The old native `build/i386-doc-find-keys-native-baseline-v1` fails with
action masks `[124,124,124,124,125,124,124,124,127,127]` and metadata
`[95,95,127,127,127,127]`. Search direction and cursor are unchanged and find
metadata is absent. Alt suppression, autocomplete descriptions, text, locks,
roles and exact caller heap pass. The native run also passes fresh arithmetic
and exact filesystem preservation with only the fixture addition. Independent
terminal audits check input hashes and exported masks/positions.

## Physical F3 versus Home plug-in Alt-F3

`tools/test-i386-doc-find-editor.py` explicitly substitutes the fixture's two
call sites with the wrapper in `tests/guest/i386-doc-find-editor/Prelude.HC`.
Eight action cases open focused DocEd(DOF_DONT_HOME) sessions and receive real
F3 or Shift-F3. A nonconsuming document callback confirms key delivery before
the host leaves the editor. The two Alt guards and all metadata cases remain
direct public-API calls. The assertion fixture, including exact heap recovery,
is otherwise unchanged. Combined source and runner are frozen in each run.

The original physical reference `build/i386-doc-find-editor-original-v2` passes
all sixteen masks 127 and exports exactly the same three binary buffers as the
direct original reference. This validates the original-body editor route with
preconfigured search options; it does not exercise the find prompt or qualify
the retained zero-flag editor, screenshots, all search boundaries or failures.

The first physical attempt expected Alt-F3 to reach DocPutKey. It completed the
eight search-key receipts, then stopped at case8. The original HomeKeyPlugIns.HC
MyPutKey hook consumes physical Alt-F3 and Shift-Alt-F3 earlier in the output
chain, inserting GREEN or LTGREEN formatting. The terminal screenshot visibly
shows green text and no document F3 callback was received. That run was stopped
after identifying this concrete routing mismatch; it remains an incomplete
fixture, not a failed search-dispatch verdict. Physical Home colour shortcuts
are a separate, still-open C1/C2 workflow. Direct DocPutKey Alt suppression does
not imply that the default physical-key pipeline does nothing.

## Native integration

`build/i386-doc-find-keys-native-v1` and
`build/i386-doc-find-editor-native-v1` pass all ten action and six metadata
masks 127 on `i386-doc-find-keys-cross-v1/kernel.img`. Both export byte-identical
original masks and all thirty cursor/direction values. The physical variant
includes eight real F3/Shift-F3 sessions; its two Alt guards remain direct API
calls for the Home-routing reason above. All cases retain the exact caller-heap
checks. Both native runs pass fresh arithmetic, input hashes, exact existing
file preservation and allocation validation. Only their fixture files are added.
Independent terminal audits recheck original exports, pins and all file tuples.

The nine printable descriptions and two ordinary typing controls in
`i386-doc-description-find-v1` and the five scheduling cases in
`i386-doc-yield-find-v1` also match their original exports. Both bootstrap
generations pass in `rebuild-doc-find-keys-v1-verified`; the cross-build passes
its 386 audit (96 BIOS/332 protected-mode instructions), and the post-export
audit matches all 1737 production source hashes. This does not establish C5
native release-generation qualification or the isolated startup-time gate.

The normal 8 MiB and full diagnostic 16 MiB welcome comparisons both pass all
307200 pixels. The diagnostic audit additionally verifies both program-probe
phases, both code-heap ownership results, both file-break cleanup phases and
all 1737 production source hashes. These concurrent runs do not qualify the
isolated startup-time budget. Public service versions and export counts remain
unchanged by this dispatcher addition.
