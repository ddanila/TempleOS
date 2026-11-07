# Window cursor positioning

FileMgr calls WinCursorPosSet to select document entries after mouse movement.
Interface 233 exposes the complete original body from Adam/WinCursorPosCore.HC,
shared with WinMgr.HC. It retains WinInside, real DocDisplay/DocLock/DocRecalc,
scroll reset and WinToTop behavior. The public arguments and default
set_cursor=TRUE are unchanged. The export is appended without renumbering
existing services.

The original-system test is tools/test-i386-win-cursor-pos.py, with a temporary
real two-line document assigned to the current task and controlled window bounds.
It covers default/null and explicit current task, selection on both lines,
scroll coordinate adjustment/reset, query-only preservation, focus, all four
outside boundaries, hidden document and hidden window, caller-owned versus
unlocked document locks, viewport transitions and preserved text. The fixture
restores task documents, geometry, flags, scrolling and prior focus.

Original v1 initially expected the final click at the first line, column 1.
Thirteen of fourteen checks passed. The diagnostic v2 captured the previous
viewport at (2,1), left by the earlier scroll-adjusted selection and preserved
by query/hidden cases. The unchanged original function adds that saved viewport
to click coordinates before recalculation, so the correct selection is the
second line, column 3. Both failed fixtures and their input snapshots remain
under build/i386-win-cursor-pos-original-v1 and -v2. The corrected test retains
all previous assertions and adds explicit before/after viewport checks.

In build/i386-win-cursor-pos-original-v3 all sixteen checks and the twelve-value
coordinate record pass. The native baseline rejects missing WinCursorPosSet
before any checks execute (build/i386-win-cursor-pos-native-baseline-v1; older
fixture with the initial coordinate expectation). It is absence evidence only.

Both bootstrap generations pass in build/rebuild-win-cursor-pos-v1-verified.
The full-content cross-build in build/i386-win-cursor-pos-cross-v1 passes the
386 instruction audit; all 1,736 post-export production source hashes match
bootstrap. In build/i386-win-cursor-pos-native-v1, all sixteen checks and the
complete coordinate record match the original, followed by exact arithmetic
pixels and filesystem validation. Inputs remain unchanged. terminal-audit.json
independently verifies pins, both output tables and byte-for-byte parity between
the shared body and pinned original. Historical references retain the previous
builder helper for their input audits.

These tests cover direct calls on the current task. Cross-task targeting,
invalid/corrupt documents, allocation/break cleanup and a complete hardware
mouse/FileMgr workflow are not qualified. The full 16 MiB startup diagnostic passes both program phases, code-heap
ownership cases, file-break cleanup cases and all 307,200 welcome pixels
(diagnostic16-audit.json). The enclosing interactive regression remains running.
C1–C5 remain open.

With the real autocomplete/settings libraries explicitly loaded, the complete
unchanged FileMgr now compiles and its three directory-chooser cases pass in
build/i386-pick-dir-win-cursor-v1. See [chooser evidence](i386-pick-dir.md) for
restoration checks and the separately observed overlapping-text defect; a
functional result does not qualify whole-window rendering.
