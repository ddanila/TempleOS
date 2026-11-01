# Original DolDoc tree operations

The complete original tree find, make, write, append and file wrappers now
compile for native tasks through `DocTreeCore.HC`; the original tree execution
and file execution bodies are shared through `DocTreeExecCore.HC`. Their
existing DolDoc, file and compiler services remain responsible for document
locking, storage, formatting and execution. This supplies the tree operations
used by the original registry; it does not implement the registry itself.

The paired original/native workflow creates nested and sibling branches,
checks found and missing paths and their returned entries, rewrites and appends
executable code, executes it, and exercises file-backed write, find, append
and execution. It returns mask 255 on the pinned and rebuilt originals and on
native at 8 and 64 MiB, with unchanged inputs
(`build/i386-doc-tree-reference-final`, `build/i386-doc-tree-rebuilt-committed-source`,
`build/i386-doc-tree-native-8m-committed-source`, `build/i386-doc-tree-native-64m-committed-source`).
The preceding native image rejected the missing `DocTreeFind` before the
fixture ran (`build/i386-doc-tree-native-red-v1`).

A separate fixture compares `DocSave` bytes after tree creation, nested append
with a sibling, and branch rewrite. All three native documents match the pinned
original byte for byte, with unchanged inputs
(`build/i386-doc-tree-bytes-reference-final`,
`build/i386-doc-tree-bytes-native-committed-source`). The first capture freed exported
buffers before collection; those invalid captures and the resulting comparison
failure are retained in `build/i386-doc-tree-bytes-reference-v2` and
`build/i386-doc-tree-bytes-native-64m-v1`. The corrected reference keeps all
three buffers live through host collection. These cases do not establish every
tree form, malformed document behavior, concurrent editing, allocation failure
or cold-reboot persistence.

The first native workflow returned the right mask but printed expression results
while `Silent` was active. The original reference suppressed them. Native
`ConsoleAnswer` now retains the result while respecting the task's silent flag;
the final workflow requires the original quiet transcript and a subsequent
ordinary answer. This does not qualify all diagnostics or all silent-output
paths. Both original rebuild generations and the native cross-build/386 audit
pass (`build/i386-doc-tree-rebuild-final.log`, `build/i386-doc-tree-cross-final`).
The first cross-build failed because an early forward declaration used `NULL`
before its native definition; the final declaration uses zero.

The registry, KeepAway application workflow, full desktop and C1–C5 remain
open. Original registry initialization, lifetime and task ownership must be
integrated rather than replaced by an in-memory shortcut.

Isolated 8 MiB startup runs passed all nine functional and exact-VGA checks,
but took 62.598 seconds on the preceding image and 62.253 seconds on the
final-source image (`build/i386-doc-tree-startup-8m-v1` and
`build/i386-doc-tree-startup-8m-final`). Both miss the 60-second gate. The
final-source runtime modules are byte-identical to those in the preceding image.
