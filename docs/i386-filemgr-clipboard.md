# FileMgr clipboard workflow reference

The fixture in tests/guest/i386-filemgr-clipboard/Contract.HC runs the complete
unchanged FileMgr through hardware keyboard input. Its observer only reads
selection, clipboard entries and filesystem state and reports readiness; it
does not invoke copy/paste or change selection. The driver pins the FileMgr
source to revision c26482bb6ad3f80106d28504ec5db3c6a360732c.

The file case selects Alpha.TXT with Shift-Down, sends Ctrl-C, navigates to
Dest, sends Ctrl-V and exits. The tree case selects the collapsed Alpha tree
with Shift-Down, sends Ctrl-Insert, then Shift-Insert at Dest. The latter
selection includes Alpha, Alpha/Empty, Alpha/Nested and its Payload.BIN.
The exact clipboard masks are 1 and 15 respectively. The binary payload is
00 01 7F 80 FE FF; the file payload is `alpha\n`.

Thirteen assertions cover the normal null return, source/copy/survivor bytes,
clipboard contents and reset, restored put/display/border documents, popup
and cwd, unchanged clipboard object identity, and copied empty directories
(or the file's non-directory type). Actual source/copied bytes are exported.
The native driver additionally requires exact new files/directories, unchanged
preexisting files and directory attributes, allocation integrity, arithmetic
output and a second boot of the mutated image. These latter checks only count
when the run reaches and passes them.

## Original reference

Both build/i386-filemgr-clipboard-file-original-v2 and
build/i386-filemgr-clipboard-tree-original-v2 pass all thirteen assertions,
exact payloads and expected clipboard masks. Their input hashes are unchanged
and terminal audits independently reverify the recorded evidence. The v1
fixtures failed compilation because original HolyC does not accept `continue`;
the guarded-body correction preserves the intended selection filter. Those
failed references and their frozen inputs remain preserved.

## Native gap

The first native file/tree runs use separate copies of the full-content image
from build/i386-window-border-cross-v1 and explicitly load real autocomplete
and settings libraries in Adam. Automatic desktop startup remains separate.
Both reach the selected-entry stage before the copy key. Native DocPutKey in
Kernel/I386/DocumentRuntime.HC has no Ctrl-C/Ctrl-Insert dispatch to ClipCopy,
although ConsoleRuntime includes the original DocClipboardCore. FileMgr routes
these keys through PutKey and consequently depends on that dispatch.
The original DocPutKey includes both copy bindings. This source finding is
a concrete implementation gap; both bounded native runs now terminate at that copy stage.

These cases do not qualify all clipboard combinations, text cut/paste,
collisions, failure cleanup, mouse drag/drop, complete visuals or FileMgr.
The compatibility inventory and C1–C5 remain unqualified.

The native file-v1 result fails waiting for READY 4, and tree-v1 fails waiting
for READY 3, after the configured 300-second stage timeout. Input traces
confirm the respective copy chords. Final screenshots retain the selected
source entries; the destination has no copied files. Independent terminal
audits verify every pinned input, the exact completed stages and unchanged
source/neighbor bytes. No post-copy assertions, native paste, restoration,
arithmetic or reboot qualification is claimed. These are failing baselines
for restoring the original clipboard key dispatch, not passing native tests.
