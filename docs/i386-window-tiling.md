# Window tiling and desktop startup

The original `WinTileHorz` and `WinTileVert` traversal bodies are shared in
`Adam/WinTileCore.HC`; the native public window API now exports both operations.
The original wrappers retain their interrupt exclusion, and the native wrappers
restore the incoming interrupt state on normal and exceptional exits. They use
the existing native task ring and original `WinHorz`/`WinVert` services. This
adds the operations; it does not yet start a second terminal or tile the native
desktop automatically.

Seven live-task cases cover one to three eligible windows, both directions,
bordered and mixed borderless geometry, derived dimensions, inhibited other
tasks, and enabled/disabled incoming interrupts. The pinned original and the
rebuilt original return seven masks of 31
(`build/i386-win-tile-reference-v5`, `build/i386-win-tile-rebuilt-final-v1`). The
previous native image rejects the missing public tiling prerequisite
(`build/i386-win-tile-native-red-v1`). The 64 MiB native comparison passes
(`build/i386-win-tile-native-64m-final-v1`). The full fixture cannot compile at
8 MiB because its backend workspace allocation exhausts the guest heap
(`build/i386-win-tile-native-8m-v1`, `build/i386-win-tile-native-8m-v2`). A
separate smaller one-window vertical case passes the original and 8 MiB native
(`build/i386-win-tile-small-reference-v2`,
`build/i386-win-tile-small-native-8m-final-v1`); it does not substitute for the
multi-window cases at 8 MiB. Two additional five-window cases cover the
original group-of-four transition in both directions; pinned original, rebuilt original and 64 MiB native pass
(`build/i386-win-tile-many-reference-v1`,
`build/i386-win-tile-many-rebuilt-final-v1`,
`build/i386-win-tile-many-native-64m-final-v1`). Other window counts, concurrent ring
mutation, callback exceptions and full task-retirement/heap recovery remain
unqualified.

The committed-source original bootstrap generations and native cross-build/386
audit pass (`build/i386-win-tile-rebuild-final-v1.log`,
`build/i386-win-tile-cross-final-v1`). On the preceding image, the physical
editor, terminal-menu and 16 MiB diagnostic regressions pass
(`build/i386-win-tile-physical-v1`, `build/i386-win-tile-term-v1`,
`build/i386-win-tile-diag-v1`).

The original startup baseline contains two focusable bordered windows, at
columns 1–39 and 41–78, both rows 2–58; the input task is not the Adam task.
The executable reference captures task rectangles and samples border and
interior pixels (`build/i386-desktop-layout-reference-v1`,
`build/i386-desktop-layout-rebuilt-v1`). It does not assert full-frame pixel
parity. Native startup still has a single full-screen no-border console. The strict
default-window check remains failing on the new image
(`build/i386-win-tile-default-window-red-v1`). An experiment that simply assigned
the first original rectangle and enabled a border produced one half-width
native console and an empty second half; its existing full-screen VGA checks
timed out at their initial screen before executing their commands
(`build/i386-desktop-geometry-large-64m-v1`,
`build/i386-desktop-geometry-large-8m-v1`,
`build/i386-desktop-geometry-physical-v1`). That incomplete experiment was
removed. Reproducing the original desktop requires the actual terminal tasks,
tiling, focus, rendering and the existing minimal-profile regressions, not
just changing one task's coordinates. C1–C5 remain open.

The preceding isolated 8 MiB startup run passed all nine functional/VGA checks
in 64.359 seconds (`build/i386-win-tile-startup-v1`). The committed-source
image also passes those checks but takes 61.542 seconds, missing the 60-second
target (`build/i386-win-tile-startup-final-v1`).

The final cross-build follows removal of a trailing blank line from the shared
source. Its `Kernel32.BIN`, `Kernel.t32m`, `ConsoleRuntime.t32m` and
`EditorRuntime.t32m` match the preceding tested build byte-for-byte; the full
disk image differs. The final tiling tests above use the committed-source image.
