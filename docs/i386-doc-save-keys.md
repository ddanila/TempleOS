# Save-key dispatch and editor integration

The native public DocPutKey dispatcher previously omitted CH_CTRLS. The retained
zero-flag VGA editor handled Ctrl-S separately, so its save support did not prove
that original-body editor sessions or other public DocPutKey callers could save.
The native dispatcher now follows the original branch: Shift toggles AUTO_SAVE,
metadata queries set the original description without performing the action,
and unshifted input calls DocWrite. Alt suppresses this branch. The character
code selects the operation even when the Ctrl scan-code bit is absent, matching
the original. Callback, incoming lock and common exit/yield behavior are retained.

## Direct original comparison

`tools/test-i386-doc-save-keys.py` runs the same fourteen cases on the pinned
original and native image, using B: RAM storage on the original and the writable
native C: volume. Every case checks exact description, autosave state, unchanged
text/cursor, incoming lock ownership, caller document roles, expected file bytes,
callback count and current directory. The cases cover:

- Save and toggle description queries, including an incoming locked document.
- Alt suppression with and without Shift.
- Autosave toggle on and off, without claiming timed autosave execution.
- Creating a file and overwriting a file while retaining an incoming lock.
- Consuming and nonconsuming callbacks.
- Null-document resolution, a missing Ctrl scan bit and invalid signature.

The pinned original `build/i386-doc-save-keys-original-v1` passes fourteen
masks 255. The old native image from `i386-doc-selected-typing-cross-v1` fails in
`build/i386-doc-save-keys-native-baseline-v1` with
`[254,254,255,255,253,253,223,223,255,223,223,223,254,255]`.
These are exactly the missing descriptions, toggle actions and five saves.
The independent terminal audit confirms thirteen sentinel files remain unchanged,
the new-file save is absent, every preexisting file tuple is unchanged, and the
volume allocation bitmap is valid. Both runs retain all input hashes. The native
failure includes a successful fresh arithmetic pixel check after the fixture.

Successful native runs also boot the mutated image again, read all fourteen
files through the public API, check their exact bytes, execute fresh arithmetic
and verify that the second boot did not change any files. This is file reopening,
not an interactive editor reopen workflow or full persistence qualification.

## Physical keyboard comparison

`tools/test-i386-doc-save-editor.py` opens DocEd with DOF_DONT_HOME, exercising the
existing original-body route. Hardware events type Z, save with Ctrl-S, toggle
autosave on and off with Shift-Ctrl-S, and accept with Escape. A guest observer
waits for actual text/cursor, saved bytes and each autosave transition before
announcing readiness for the next key. The return checks accepted result, caller
document roles, unlocked document, exact serialized bytes and autosave disabled.

The pinned original `build/i386-doc-save-editor-original-v1` passes mask 63 and
exports the exact seven bytes `Z\x05Keep\n`, both from the edited document and a
fresh FileRead. Successful native runs additionally require the exact persisted
file and fixture additions, unchanged existing file tuples, valid allocation,
and the same seven bytes after a second boot. Screenshots are retained as
observations; this runner does not assert visual equivalence.

The ordinary zero-flag editor still has a separate save implementation. Its
migration remains tracked in [normal DocEd](i386-doced-normal.md). Save As,
failure/recovery behavior, timed autosave, complete keyboard dispatch, heap
balance and full desktop/release qualification remain open. No compatibility
inventory item becomes qualified from these bounded tests.

## Native verification

The implementation image is `build/i386-doc-save-keys-cross-v1/kernel.img`.
`i386-doc-save-keys-native-v1` passes all fourteen masks 255 and all fourteen
second-boot FileRead checks. `i386-doc-save-editor-native-v1` passes mask 63,
exact original text/cursor bytes and cold-boot readback. Both runs pass arithmetic
pixel checks before and after reboot, unchanged-input checks, exact existing
file preservation, only the declared new file additions and allocation validation.
Independent terminal audits recheck exported results, source hashes and complete
file tuples after reboot.

The nine description queries and two ordinary typing controls
(`i386-doc-description-save-v1`) and five scheduling cases
(`i386-doc-yield-save-v1`) remain passing with byte-identical original exports.
Both bootstrap generations pass in `rebuild-doc-save-keys-v1-verified`; the
post-export source audit matches all 1737 production files. The native build
passes its 386 instruction audit (96 BIOS/332 protected-mode instructions).
The 8 MiB normal welcome matches all 307200 pixels. These are concurrent
functional runs, not the isolated startup-time gate or C5 release qualification.

The full 16 MiB diagnostic run also passes the exact 307200-pixel welcome,
both program-probe phases, both code-heap ownership results and both file-break
cleanup phases. `i386-doc-save-keys-cross-v1/diagnostic16-audit.json` records
these checks and revalidates all 1737 production source hashes. No public service
version or export count changes are required by this dispatcher addition.
