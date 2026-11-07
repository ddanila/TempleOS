# Picker-key dispatch

The public native DocPutKey dispatcher now routes F4 and Shift-F4 to the original
PopUpPickFile and PopUpPickDir services. It unlocks the caller document while the
picker is active, relocks it before insertion, inserts through DocPrintPartial,
and frees the returned allocation. Metadata returns the original descriptions;
Alt suppresses picker dispatch and Ctrl-F4 remains on the autocomplete route.
The temporary returned path is also freed if insertion raises an exception.

The previous zero-flag VGA editor had a separate F4 implementation. That did not
supply this public dispatcher behavior or the original-body DocEd route. This
change is part of the migration tracked in [normal DocEd](i386-doced-normal.md),
not a full editor or FileMgr qualification.

## Original direct-dispatch baseline

`tools/test-i386-doc-picker-keys.py` packages the unchanged original FileMgr and
runs `tests/guest/i386-doc-picker-keys/Contract.HC` against the original system or
native image. Six metadata cases check F4, Shift-F4, Alt suppression and the two
Ctrl-F4 autocomplete descriptions, with unchanged text/cursor, document roles,
popup role and lock state.

Five action cases use real focused FileMgr popups and hardware navigation:
select a file, select a directory, cancel each picker, and select a file with an
incoming caller lock. An observer requires the correct directory entry at each
navigation checkpoint and sees the caller document unlocked during the popup.
Returned text and cursor must show insertion between Before and After, or no
change on cancellation. Caller document/popup roles, directory, description and
incoming lock state must be restored. The runner checks every serialized output
byte against an independent expected path (accounting for T: versus C:).

`build/i386-doc-picker-keys-original-v1` passes metadata masks 15 six times and
action masks 127 five times. The old native image in
`build/i386-doc-picker-keys-native-baseline-v1` fails with metadata
`[14,14,15,15,15,15]` and action `[60,60,63,63,60]`: the two picker descriptions
are absent, no popup opens, and no path is inserted. The fixture permits an
immediate no-popup return so this is a completed mismatch observation, not a
picker wait timeout. Both original and native terminal audits retain verified
input hashes. The native run passes fresh arithmetic and exact filesystem
preservation, with only the fixture files added and allocation integrity intact.

The underlying [picker service tests](i386-pick-file.md) remain separate evidence.
These dispatch tests do not prove complete picker gestures, selection ownership,
heap balance, arbitrary filename characters, failure recovery, border/client
visual equivalence or full keyboard dispatch. The exception cleanup added here
still needs an injected-failure/resource observation before it can be qualified.

## Physical-key reference

`tools/test-i386-doc-picker-editor.py` uses the same assertion fixture, replacing
only its two DocPutKey call sites with a test wrapper. Metadata calls still
invoke public DocPutKey directly. Action calls open DocEd(DOF_DONT_HOME), focus
the caller, and wait for real F4/Shift-F4 keyboard events. A second observer
announces editor readiness and popup closure so the host can leave the editor
only after picker completion. The five real picker sessions and all byte/state
assertions remain unchanged. The combined source is frozen with each run.

`build/i386-doc-picker-editor-original-v3` passes all six metadata masks 15 and
five action masks 127. This covers original-body editor routing, not migration
of the retained zero-flag editor. No screenshot equivalence is asserted.
The first physical reference never ran: the generated #undef line caused an
original compiler error, preserved in its terminal screenshot. The second
reached the editor but exposed an uninitialized fixture case counter; it was
interrupted after the invalid readiness value was observed. The final fixture
uses explicit call-site substitution, an initialized counter and focus setup.
Those two incomplete runs are not compatibility verdicts.

## Native integration and remaining physical run

`build/i386-doc-picker-keys-native-v1` passes all six metadata masks 15 and five
action masks 127 on `i386-doc-picker-keys-cross-v1/kernel.img`. Its exact exports
match the original, normalizing only the T:/C: fixture drive prefix in inserted
paths. The independent terminal audit rechecks every input hash and serialized
result, all existing file tuples, exact fixture additions and allocation integrity.
A fresh arithmetic result also passes its pixel oracle.

Both bootstrap generations pass in `rebuild-doc-picker-keys-v1-verified`.
The cross-build and post-export audit verify all 1737 production source hashes;
the 386 audit checks 96 BIOS and 332 protected-mode instructions. Normal 8 MiB
and diagnostic 16 MiB welcome images match all 307200 pixels. The diagnostic run
also passes both program-probe phases, both code-heap ownership results and both
file-break cleanup phases. These concurrent functional runs are not the isolated
startup-time gate or C5 release qualification. Public versions/exports are unchanged.

The fourteen save-key cases and their fourteen cold-boot readbacks remain passing
in `i386-doc-save-keys-picker-v1`. Five scheduling cases remain passing in
`i386-doc-yield-picker-v1`; independent audits match their original exports and
verify exact filesystem changes and input hashes.

The native physical-key run `i386-doc-picker-editor-native-v1` is still active at
this checkpoint. Its first completed session has the expected inserted path;
remaining sessions and terminal state/filesystem checks must finish before that
runner is counted as passing. The direct API pass does not substitute for this
physical-key result. Process details are retained in
`build/doc-picker-verification-processes.json`; observe that process before
considering a repeat.
