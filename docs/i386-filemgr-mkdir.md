# FileMgr directory creation and cancellation

The test uses the complete unchanged original FileMgr in normal mode. A read-only
observer identifies the selected fixture directory and real class-form document;
the host sends hardware keyboard events. It presses `d`, types `Made`, accepts
with Escape, then presses `d`, types `Cancelled`, cancels with Shift-Escape, and
exits FileMgr. The observer does not alter selection, document data or filesystem
state to make the workflow advance.

Nine guest assertions check the normal-mode null return, created directory,
absent cancelled directory, restored put/display/border documents, restored
popup pointer and working directory, and unchanged `Keep.TXT` bytes. The native
host also checks serialized files/directories, filesystem integrity, arithmetic
pixels and a second boot that reads the created/cancelled directory state.
Settings and autocomplete are loaded explicitly from their real delivered
libraries. This does not qualify automatic startup loading.

Run tools/test-i386-filemgr-mkdir.py without a disk for the pinned original, or
with a full native disk for the native workflow. Each run requires a fresh output
directory and preserves its fixture, runner, key trace, stage screenshots and
input hashes. The original uses its writable B: drive; native uses C:.

build/i386-filemgr-mkdir-original-v1 passes all nine assertions and all five
observed stages. Input hashes are independently reverified in terminal-audit.json.
The native workflow in build/i386-filemgr-mkdir-native-v1 produces the exact same
nine values and passes serialized file/directory checks, preservation of all
original files/directories, filesystem integrity and concluding arithmetic. Its
initial reboot probe uses conditional syntax rejected by the native console, so
that result.json correctly remains failed.

The corrected reboot expression multiplies the boolean condition by `6*7`,
avoiding literal `42` in source text that the generic pixel matcher could mistake
for an answer. build/i386-filemgr-mkdir-reboot-v3 passes this probe on a copy of
the same preserved disk: the actual answer is at column 0, row 10; file/directory
contents and input hashes remain unchanged. The intermediate v2 probe did match
a literal in its source, although an independent full answer-row audit confirms
its actual result too. Historical drivers and both observations are preserved.

combined-audit.json composes the verified workflow and corrected reboot evidence.
It proves that the final driver differs only in that reboot expression; the
complete final driver was not rerun as one session. This avoids repeating the
already completed create/cancel workflow while retaining the original failure.

This is one normal FileMgr workflow. Navigation, rename, delete, clipboard copy,
drag/drop, editor/execution/help integration, disk operations and complete visual
behavior still need their own end-to-end evidence. FileMgr and C1–C5 remain
unqualified.
