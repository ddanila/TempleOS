# VGA palette services

The original task settings stack snapshots and restores the hardware palette.
ConsoleRuntime 144 exports `GrPaletteColorSet`, `GrPaletteColorGet`,
`GrPaletteSet` and `GrPaletteGet`. The bulk operations share the original
bodies. Native per-color operations access the VGA DAC directly and preserve
the caller's interrupt state around each register transaction. The port runs
one CPU, so those non-yielding transactions cannot be interleaved by another
task. The text-mode and multiprocessor paths remain outside this implementation.

The pinned original reference sets and reads sixteen varied colors, checks
individual and bulk reads, saves exact quantized values, and restores the
initial palette (`build/i386-vga-palette-reference-v2`). Both original bootstrap
generations and the native cross-build/386 audit pass (`build/rebuild-test`,
`build/i386-vga-palette-cross-v2`). The native hardware comparison passes all
six checks, including both interrupt states, with exact original quantized
values and unchanged inputs (`build/i386-vga-palette-native-64m-v2`). This
concurrent run does not qualify startup timing. This focused dependency does not qualify
the task settings stack or C1–C5.
