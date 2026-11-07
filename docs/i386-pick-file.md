# File and directory chooser selection

The complete original PopUpPickFile wrapper is shared through
Adam/DolDoc/DocPickFileCore.HC. Its function text is byte-identical to pinned
revision c26482bb6ad3f80106d28504ec5db3c6a360732c. Native Console 234 appends
export 628, _POP_UP_PICK_FILE, and PublicFiles.HH declares the original
optional-directory signature. It calls the actual popup and unchanged FileMgr
in file-picking mode, allocating the result in the caller's heap.

The fixture runs five actual popup sessions. A read-only observer reports
selected FileMgr entries; the host sends Down and Escape or Shift-Escape.
It never changes selection or invokes a FileMgr action itself.

1. Default current directory: navigate past Nested and accept Alpha.TXT.
2. Explicit Nested directory: navigate to and accept Marker.TXT.
3. Explicit directory: accept the directory itself in file-picking mode.
4. Navigate to Alpha.TXT and cancel with Shift-Escape.
5. Use PopUpPickDir, navigate to Alpha.TXT, and accept its parent directory.

Each result must be allocated, have the exact expected string, and belong to
the caller heap. Each session must restore put/display/border documents, the
previous popup pointer and caller cwd. Returned names include their terminating
NUL in exported evidence. The native test loads the real autocomplete/settings
libraries in Adam, checks post-session arithmetic and verifies the existing
filesystem remains intact. Automatic desktop startup integration is separate.

## Original reference

Build i386-pick-file-original-v1 passes five masks of 255. The first two
returns are the exact selected full filenames; accepting a directory in file
mode and cancellation both return allocated empty strings; choosing a file in
directory mode returns its parent. The terminal audit independently rechecks
all input hashes and exported strings. No returned directory is silently
accepted as a filename.

The old native image in build/i386-pick-file-baseline-v1 rejects fixture
compilation at PopUpPickFile before any popup session. Its terminal audit
reverifies all pins, and the pre-version-change build helper is preserved.
Both original bootstrap generations pass in
build/rebuild-pick-file-v1-verified with 1,737 production sources. The corrected native result is recorded below. These sessions do not qualify mouse selection, every navigation
key, faults, interruption, complete visuals or all FileMgr behavior.

The full64 cross-build passes the 386 instruction audit (96 BIOS, 332 protected
mode), with all 1,737 production hashes matched to the verified bootstrap after
export. Normal8 startup and full16 startup diagnostics both reach DONE and
match all 307,200 welcome pixels. The full16 terminal audit checks both program,
code-heap ownership and file-break cleanup phases. Concurrent execution does
not qualify isolated startup timing or the full enclosing interactive suite.

## Corrected native evidence

Build i386-pick-file-native-v1 passes all five masks of 255, all five returned
strings and post-session arithmetic. The masks match original-v1 byte for byte;
the strings differ only in the fixture drive letter, T: versus C:. The driver
verifies filesystem allocation structure. The independent terminal audit
rechecks every pinned input, all original file tuples and directory attributes,
and the exact added fixture paths and bytes. No chooser action changed files.

After this complete guest run, the host file guard was tightened to check
fixture bytes as well as changed path sets. host-guard-replay.json records
replaying that final guard on the terminal image and rejecting a corrupted
fixture in an in-memory negative control. Guest source and key sequence are
unchanged; this is composed guest/host verification, not a single run of the
final driver. The frozen runner preserves the executed version.

The workflow map and inventory retain unqualified status for the complete
application. Actual editing, help/execution integration, drag/drop, failure
cleanup, complete visuals and automatic desktop settings startup remain open.

The later build/i386-pick-file-yield-v1 regression runs the final driver on
the yield-corrected image and passes in one complete session, including its
stricter host fixture-byte guard. Five masks of 255 and all returned names
match the original apart from drive letter. Arithmetic, allocation integrity,
original files and exact fixture bytes pass; terminal-audit.json independently
checks directory attributes, names, input hashes and the full file guard. This
new run supplies single-session final-driver evidence beyond the earlier
composed native-v1 audit. Full visual, failure and application coverage remain
open.
