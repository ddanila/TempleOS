# Original HomeSys desktop layout

The current x64 rebuild passes the original layout oracle in
`build/fallback-minimum-desktop-layout-classic-v1/result.json`. Its configured
Once records exactly two visible focusable tasks: bordered windows at columns
1–39 and 41–78, both rows 2–58. The captured User has height 57. This is the
existing explicit 83-word oracle, not a newly fitted expectation.

The same capture Once runs after the actual HomeSys `StartUpTasks` body on the
current native full-content cross image. The disposable preflight loads the
original MakeAC and HomeSys in Adam, installs the capture at the actual Once
lookup path, and invokes StartUpTasks explicitly. Both User children start and
the queued Once executes. This is an integration preflight, not normal boot.

`fallback-minimum-desktop-layout-native-v1` fails the unchanged layout oracle:
three visible focusable windows have columns 1–19, 21–39 and 40–60. The first
two have borders at rows 2–58; the third is borderless at rows 1–59. The raw
83-word export and failure receipt are retained. Input hashes remain unchanged.

A second run, `fallback-minimum-desktop-layout-native-v2`, repeats that failure
and exports all six tasks in actual window-list order. The two Users are shown
and focusable. The third visible window is the existing bootstrap console,
with no border and no self-focus inhibition. Hidden Adam also has no self-focus
inhibition and receives columns 61–78. WinMgr and the other hidden worker have
the inhibition bit set. The shared original WinTileVertCore counts tasks by
self-focus inhibition, including hidden tasks; four participants therefore
explain the quarter-width geometry. This identifies both the extra bootstrap
console and hidden Adam's participation without changing the tiling oracle.

The native preflight does not retire the bootstrap console or implement the
normal HomeSys boot transition. A disposable policy experiment separately tests
inhibiting hidden Adam and hiding/inhibiting the bootstrap console before
StartUpTasks. Even a geometry pass there would not qualify normal boot, task
retirement, full raster parity, Once/home semantics, autocomplete content,
resource recovery or C1–C5. Production startup remains unchanged while the
current-source native module chain is pinned.
