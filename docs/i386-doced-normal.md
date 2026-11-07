# Normal DocEd original comparison

The public zero-flag `DocEd(doc)` still enters the retained native keyboard/VGA
editor. Nonzero flags and form documents enter `NativeOriginalDocEd`, the shared
original editor body. This distinction is a C2/C4 compatibility gap, not an
intentional architecture exception. Neither path is fully qualified.

`tools/test-i386-doced-normal.py` and
`tests/guest/i386-doced-normal/Contract.HC` exercise two real editor sessions:
type uppercase Z, accept with Escape, then repeat and cancel with Shift-Escape.
The fixture checks active put/display/border documents, filename title, parent
and owner links, text attribute, geometry and lock state. It checks return value,
restored caller roles/title/attribute, unlocked document, retained parent/owner,
and the exact 15 serialized bytes `Z\x05First\nSecond\n` after each exit.
Shift-Escape rejects the session but does not undo the in-memory edit.

The caller is focused and visible, with children behind it, autocomplete disabled
and restored through its public API, and inner geometry (1..78, 2..58). Borders
are enabled before setting geometry and restored before restoring geometry.
The host moves the mouse outside the client before capturing each frame.
Four 624-by-456 client images must settle across three consecutive captures.
Only the known 8-by-8 caret cell is excluded (284480 compared pixels per frame);
serialized cursor placement is independently checked.

`tools/audit-i386-doced-normal-reference.py` verifies all original input hashes,
state exports and focus observations. It independently renders First/Second or
ZFirst/Second from FontStd and requires both the raw screenshot crop and saved
normalized client image to match every compared pixel. Native runs require this
audit and pin its client hashes. They also require fresh arithmetic with an exact
42 pixel oracle, unchanged existing filesystem entries, only the packaged fixture
addition, allocation validation and unchanged input hashes.

## Original baseline

Both `build/i386-doced-normal-original-v5` and
`build/i386-doced-normal-original-dont-home-v1` pass the session and independent
visual audit. Each records four active masks 127, two return masks 127, exact
serialized text and focus on the caller at all four checkpoints. The latter
passes DOF_DONT_HOME; both fixtures explicitly start at DocTop, so their expected
text and client images are identical. This control exercises the existing shared
editor route on native without changing production dispatch.

Original guests use two CPUs, TCG and 2048 MiB; native guests use the helper's
64 MiB KVM configuration. These are functional comparisons, not the isolated
8 MiB startup gate or release resource qualification.

## Native baseline and routing control

On `build/i386-doc-selected-typing-cross-v1/kernel.img`, the corrected default
comparison `build/i386-doced-normal-native-baseline-v2` fails with active masks
113 four times and return masks 95 twice. The active failures are the missing
original border document, filename title and parent/owner relation; the return
failure is the retained parent/owner relation. Geometry now passes. Both sessions
serialize the exact expected bytes. Client differences are 524 pixels before
insertion and 609 afterward in each session: the legacy full-screen heading and
text placement differ from the original window client.

The `build/i386-doced-normal-native-dont-home-v1` control passes all four active
masks 127, both return masks 127, exact text and all four client images with zero
pixel differences. Both native runs finish fresh arithmetic with a complete 42
pixel oracle, preserve every existing file tuple and add only the fixture, pass
allocation validation and retain all input hashes. Their `terminal-audit.json`
files independently recheck hashes, exports, file tuples and pixel differences.
The failing default verdict remains failing.

Visual inspection of the full control screenshot shows another open difference:
the client is correct, but the original visible border/status decoration is
absent. The border-document state check does not establish border rendering.
This test intentionally compares only the declared client rectangle; full-frame
editor and desktop rendering still need their own original oracle.

## Fixture history and limits

Original v1-v3 did not reach a complete typing comparison. The early captures
included a changing autocomplete window; moving the mouse to the upper-left
also opened a menu. The corrected fixture disables autocomplete explicitly and
moves the mouse to the lower-right. Original v4 passed the text and pixel checks,
but the first native baseline exposed incorrect fixture border/geometry order.
Toggling borders changes inner geometry on a previously borderless native task;
restoring geometry first clipped the first console column. That run is retained
as fixture-correction-required, not a matched-geometry compatibility verdict.
The v5 reference and subsequent controls use corrected ordering.

This test does not qualify default desktop geometry, autocomplete-enabled editor
interaction, the border raster, save/reboot/reopen, all shortcuts, selection,
mouse editing, undo, resource recovery or heap balance. The remaining dispatcher
workflows are enumerated in [DocPutKey](i386-doc-put-key.md). Migrating zero-flag
DocEd to the original body must integrate those real service paths: the retained
editor currently intercepts save, help, execution and other commands absent from
the public DocPutKey dispatcher. Passing this small session alone cannot justify
removing those working paths or declaring the full editor compatible.
