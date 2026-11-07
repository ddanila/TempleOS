# FileMgr rename and delete workflows

Two fixtures exercise the complete unchanged original FileMgr in normal mode
through hardware keyboard events. Both use a read-only state observer to tell
the host when a file, form or confirmation button is ready; the observer never
changes selection, enters text or invokes a FileMgr action itself.

The file workflow starts with Alpha.TXT and Keep.TXT. Down selects Alpha.TXT,
`r` opens the filename form, and typing Bravo.TXT followed by Escape performs
the rename. The rebuilt list selects Keep.TXT, so Up selects Bravo.TXT. Delete
opens the real confirmation menu. Shift-Escape cancels the first attempt and
preserves bytes; the second attempt confirms the observed OKAY button. After
deletion, Keep.TXT is selected and Escape exits FileMgr.

The directory workflow follows the same key path with Alpha and Bravo. Alpha
contains Nested/Payload.BIN with bytes 00 01 7F 80 FE FF and an empty directory.
The actual FMRename directory branch uses CopyTree followed by DelTree. The
fixture checks the binary payload and empty directory after rename, payload after
cancellation, and disappearance of both old/new tree names after confirmation.

Eleven file assertions cover the null normal-mode return, rename/cancellation
bytes, absence of old/new target names after confirmation, unchanged neighbor
bytes, restored put/display/border documents, popup pointer and working directory.
The directory test adds its empty-directory assertion. Both export actual renamed
bytes read from the filesystem. Native host checks preserve every preexisting
file and directory, require only the expected remaining fixture files/directories,
validate allocation structure, and boot the mutated disk to check persisted
absence/presence. The reboot expression has no literal answer for the pixel
matcher to confuse with command output.

## Original evidence

The first file run expected the renamed entry to stay selected. It was deliberately
interrupted after source inspection and its final screenshot established that
FMRebuildDoc selects the next file when the old name disappears. No application
fix was made for that original behavior. The corrected fixture asserts next-file
selection and performs real Up navigation before deletion.

build/i386-filemgr-edit-original-v2 passes all eleven assertions and all ten stages;
renamed.bin is exactly `alpha\n`. build/i386-filemgr-tree-edit-original-v1 passes
all twelve assertions and all ten stages; renamed.bin is exactly the six binary
bytes. Both terminal audits independently reverify input hashes. The cancelled
first run, its incorrect fixture and its screenshot remain preserved.

## Native scope

build/i386-filemgr-edit-native-v1 passes the complete final driver, including
all eleven original-equivalent rows, actual renamed bytes, arithmetic, serialized
filesystem validation and a second boot. The actual reboot answer is at column
0, row 11, after the wrapped input. terminal-audit.json independently rechecks
pins, original comparison and exact post-reboot file/directory preservation.
build/i386-filemgr-tree-edit-native-v1 also passes the complete final driver,
all twelve original-equivalent values, exact binary payload and reboot. Its
terminal audit verifies all original files/directories remain intact and only
the fixture root and Keep.TXT remain after recursive deletion. Both native runs
finish with unchanged inputs and actual reboot answers at column 0, row 11.
They use separate full-content image copies and explicitly load real settings
and autocomplete libraries in Adam. Automatic startup loading remains open.

These cases do not cover rename collisions, copy/delete failures, cancellation
under break or close, allocation cleanup, clipboard, drag/drop, all navigation,
editor/help/execution integration, media operations or complete visual parity.
The full coverage map is [i386-filemgr-workflows.md](i386-filemgr-workflows.md).
FileMgr and C1–C5 remain unqualified.
