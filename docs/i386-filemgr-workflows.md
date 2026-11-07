# FileMgr workflow coverage

The implementation under test is the complete byte-identical FileMgr from pinned
revision c26482bb6ad3f80106d28504ec5db3c6a360732c. The current native full-content
image supplies the program, but tests explicitly load the real autocomplete and
settings libraries through AdamFile before including FileMgr. Automatic desktop
startup integration remains open.

The table separates executable original observations from workflows identified
in FileMgr.HC and Doc/FileMgr.DD that still need an end-to-end reference. Primitive
API tests do not qualify an application workflow. FileMgr remains unqualified.

| Workflow | Required observation | Current evidence |
| --- | --- | --- |
| Directory chooser: default, explicit directory, cancellation | Exact allocated result, caller documents/popup/cwd restored, normal console usable | Original reference and native three-case tests pass; docs/i386-pick-dir.md and build/i386-pick-dir-border-v2/terminal-audit.json |
| Directory chooser: selected file | Escape returns its parent directory; exact restoration | Original and native PopUpPickDir on a selected file return its parent with exact caller ownership/restoration; docs/i386-pick-file.md |
| File chooser: file, directory, cancellation | Exact filename or allocated empty result, restoration | Original and native five-case chooser test passes: default/explicit filenames, allocated empty directory/cancel results and caller ownership/restoration; docs/i386-pick-file.md |
| Normal mode: create directory and cancel another creation | Real filename form, created/absent paths, surviving bytes, restoration, persisted native result | Original and native workflow plus corrected native reboot probe pass; docs/i386-filemgr-mkdir.md |
| Normal mode: file navigation and rename | Down selects Alpha.TXT; rename preserves bytes; rebuild selects Keep.TXT; Up selects renamed Bravo.TXT | Original and native pass eleven total edit-workflow checks, exact renamed bytes and native reboot; docs/i386-filemgr-edit.md |
| Normal mode: file deletion cancellation/confirmation | Cancellation preserves bytes; confirmed deletion removes only the target; neighbor selection, restoration and native reboot | Original and native complete drivers pass; docs/i386-filemgr-edit.md |
| Normal mode: recursive directory rename/delete | Nested binary payload and empty directory survive rename; cancellation preserves payload; confirmation removes tree and preserves neighbor | Original and native pass twelve checks, exact binary bytes, filesystem and reboot; docs/i386-filemgr-edit.md |
| Tree navigation and multi-selection | Expand/collapse, cursor/page movement and Shift selection preserve the intended selected entries | Down/Up paths and Shift-Down selection of a file or collapsed tree (including hidden descendants) have original/native references; broader navigation remains open |
| Clipboard copy/paste | Ctrl-C/Ctrl-Insert and Ctrl-V/Shift-Insert preserve selected file/tree bytes, avoid duplicate descendants, maintain clipboard ownership across rebuilds | Original and corrected native file/tree workflows pass thirteen assertions each, exact selection/clipboard masks and payloads; native filesystem preservation and reboot pass. See docs/i386-filemgr-clipboard.md |
| Drag/drop | Actual mouse selects source/destination; files move, directories copy/delete; self/descendant moves are rejected without loss | Source/document-defined; no whole-workflow reference yet |
| Edit and return | Space/click opens editor; Shift-Space opens plain editor; save/reopen bytes and FileMgr state restored | Source/document-defined; standalone editor tests are not FileMgr integration evidence |
| Execute and return | F5 executes in popup; Shift-F5 executes in Adam; effects, exceptions and returned UI state checked | Source/document-defined; standalone include/job tests do not qualify these paths |
| Command menus and help | Enter/right click and pull-down menu dispatch equivalent actions; help opens and returns without state loss | Source/document-defined; menu primitives are not complete integration evidence |
| Change removable media | Selected drive is remounted, list rebuilt, previous data is not silently reused | Source-defined; whole workflow open |
| Mount/unmount image | Correct selected image/drive is mounted or removed, protected boot drive remains available | Source-defined; whole workflow open |
| Format | Cancel changes nothing; confirm formats only selected test drive and refreshes view | Original Fmt primitive evidence exists; FileMgr workflow open |
| Make ISO | Selected directory becomes a valid image with exact tree bytes and format metadata | RedSeaISO primitive evidence exists; FileMgr workflow open |
| Burn ISO | Correct optical destination, image bytes, command/error handling and UI recovery | DVDImage partial read/rejection evidence does not qualify successful burn workflow |
| Interruption and failure cleanup | Break, close, allocation/IO failures restore task/doc/menu/clipboard ownership and allow reuse | Related provider tests exist; whole FileMgr cases remain open |
| Visual behavior | Window contents, focus, menus, controls, transitions and occlusion agree with original observations | Exact border-cell differential and settled chooser-interior composition checks pass; whole application visual qualification remains open |

The rename/delete fixtures use an observer that only reads application state and
records evidence. All navigation, form entry and confirmations come through host
keyboard events. Original v1 of the file test expected the renamed entry to stay
selected; a captured original window instead selected the next file. The corrected
reference explicitly tests that selection and navigates Up before deletion.

Native durability checks use a second boot of the actual mutated disk. The
original workflow uses its writable B: RAM drive, so these are not a claim that
an original RAM drive persists across reboot. Normal-mode file and directory
runs use separate images. Settings/autocomplete startup, unobserved workflows
and complete C1–C5 qualification remain open.
