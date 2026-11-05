# Keyboard gate on the delivered welcome desktop

The full build gate's normal keyboard session now explicitly selects the
existing welcome-document mode. The prior call expected a four-line plain
terminal, timed out before submitting input, and never exercised its workload.
The session retains editing, cancellation, wrapping, tabs, sixty-line scrolling,
mouse interaction and the complete later component command sequence. Welcome
mode uses the real document wrapping/color expectations and leaves WinMgr live.

The old welcome branch used simpler speaker on/off commands. Both presentation
modes now run the stronger existing probes: PIT channel-two counter samples
must reach the concert-A period range, speaker bits must be set/cleared, and
interrupt-enable state must recover. The octave/reset check remains. No
production code, RAM, allocation size or fixture command buffer limit changes.

## Verified scope

`build/i386-welcome-keyboard-sound-v1/result.json` passes keyboard editing and
all three sound commands on the delivered normal image at 8 MiB, KVM 486 without
FPU, with live WinMgr, all checkpoint pixels and unchanged input pins. The raw
keyboard sequence includes 60 empty lines plus editing/error/tab input; the
result's `native_commands=3` counts the sound submissions, not all key events.
It does not include the separate compiler/API command group. Startup is 33.17
seconds. Exact raster checks retain the original font and welcome styles.

The current complete default TCG build gate is running in
`build/i386-welcome-keyboard-gate-minimal-v1`. It has passed diagnostic guest
completion, complete welcome pixels, exact diagnostic disk immutability and
entered normal interaction. Keyboard editing, mouse, the strengthened sound
probes and WindowServiceCheck pass. The frozen `progress.json` and
`input-progress-log.txt` record this checkpoint as **incomplete**, not a complete
suite result. All sixteen module files match the preceding candidate; the
1,361-file delivered-source audit passes.

A separate 8 MiB KVM compiler-group run in `build/i386-welcome-compiler-v1` is
also running. Its public task/CPU layout checks have been reached. Neither live
run proves its remaining commands, recovery paths or later full-gate checks.
Their terminal outcomes must be collected before qualification. The welcome
session's raw-terminal upload counters do not measure WinMgr frame transfers;
existing pixel checks remain active. Complete minimal-profile regressions,
application inventory qualification and C1-C5 remain open.
