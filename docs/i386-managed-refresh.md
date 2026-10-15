# Normal-boot managed document refresh

Normal native startup now starts a resident managed WinMgr after graphics and
public raster initialization. `sys_winmgr_task` names that real task. Its parent
is the kernel memory root, not the console/document owner. Drawing callbacks run
as WinMgr, preserving the original callback execution context. The persistent
drawing context is associated with WinMgr; the frame context retains the console
association, matching the original initialization split.

## Scheduling, view admission and recovery

The worker requests frames at a nominal 33 ms cadence. It uses the numeric window
snapshot and shared original per-window body. Dynamic documents update without
application DocRecalc or presentation calls. Completed physical presentations
advance the existing refresh observations; this does not establish a measured
30 fps release profile.

The retained transcript/editor bridge is still present. Automatic presentation
is requested for a shown custom display document (different from put_doc), task
drawing or controls. Covered windows do not force presentation. Default legacy
transcript/editor views retain their existing path. A focused raw task inhibits
automatic presentation. New public tasks enter normal display mode. After the
frame lease is acquired and visibility updated, admission is checked again so a
queued request cannot upload a view that is no longer active. Raw terminal
uploads defer while an automatic view owns presentation.

Public Kill refuses the real WinMgr, as in the original system. Owner/document
retirement uses a private unwind request: the existing one-shot end callback
throws WinAbort to the resident outer loop. The document/window/frame scopes
release their resources, then the same worker can process another frame.

Actual worker termination runs a resident cleanup that restores the kernel-root
anchor before the task is freed. A new private console-service callback is
polled by the kernel idle root and recreates a terminated worker. This works
while the console/application sleeps; it does not depend on user input or a
test supervisor. OutMem defers restart for a second instead of leaving an
unhandled exception in the idle root.

An unexpected per-window callback failure unwinds the frame, hides the offending
window, emits an original-style exception/caller report and delays for three
seconds without retaining the frame lease. General/background failure debugging
is not yet the complete original window-manager policy.

## Interface and test separation

Console interface version 84 adds the private `window_ensure` callback, growing
its 32-bit service table from 44 to 48 bytes. It exports NativeWinMgrStart as
symbol 226. Memory interface version 25 adds normal display defaults and public
WinMgr Kill protection; its table and 49-symbol count are unchanged. Public CTask
layout is unchanged. Kernel/provider versions and service entry addresses are
checked together.

The OS starts refresh on normal boot. Explicit component fixtures pause it using
ordinary Suspend after boot; their custom startup-check results record the pause
request and the extra setup command. Group sessions log the same setup step and
include it in the submitted command count. Automatic-refresh, worker-lifecycle,
worker-error and normal startup-memory checks explicitly leave it running.
This isolates controlled manual presentations without adding a test-only OS boot
mode or requiring a person to run the trivial checks.

```
python3 tools/test-i386-doc-auto-refresh.py IMAGE --out OUT
python3 tools/test-i386-auto-worker-lifecycle.py IMAGE --out OUT
python3 tools/test-i386-auto-worker-error.py IMAGE --out OUT
```

The unchanged application behavior in the A/B gate selects a document, changes
its tag value and sleeps/waits for keys. Neither phase calls DocRecalc or a frame
helper. The prior image fails the first A observation in
`build/i386-c2-managed-refresh-red/result.json`; phase B is unexecuted there.

The 14-command lifecycle fixture checks real callback Fs, public Kill rejection,
owner-driven cancellation, exact parent heap and presentation reuse. A second
case clears the worker's end callback and exits inside the tag: kernel-root
supervision must produce a new task number and a successful callback on that
new worker. It does not assume task addresses cannot be reused.

The 14-command error fixture checks hide/context, retained old tag, released lock,
unchanged worker identity and a real reporting/cooldown path. It restores the
original view and measures parent heap before deliberately resetting the fixture
console. The expected kernel error marker is checked independently. This is not
full stack-symbol or debugger qualification.

## Remaining desktop acceptance

The automatic full-window A/B case is one executable desktop baseline, not C2
completion. Protected per-frame derived-control updates, ODE/event work, mouse
and cursor composition, complete legacy-view/stdout/input integration, overlapping
window arbitration and held-frame raw/debug transitions remain open. Root/Adam
role compatibility and all bundled app/demo workflows still require qualification.
C1–C5 remain incomplete; complete native generations and release profiling remain
C5 work.

## Checkpoint evidence and open regressions (2026-10-15)

The final cross-built image is
`build/i386-c2-managed-refresh-final-cross/kernel.img`. Original self-rebuild,
cross-build and the 386 boot instruction audit pass. Final-image result files
under `build/i386-c2-managed-refresh-final-*` record passing automatic refresh
(9 commands), worker lifecycle (14), worker error (14), window traversal (36),
whole-window update (48), and window/graphics/text-frame groups (24 submissions,
including the manager-pause setup). Normal 8 MiB startup passes 9 commands in
47.47 seconds on `486,-fpu`, without loading build providers.

Two additional checks do **not** qualify at this checkpoint. The 8 MiB diagnostic
image session (`build/i386-c2-managed-refresh-final-diagnostics`) exits without
a passing result: its debug log ends in `FAIL native kernel` after a 307200-byte
allocation fails during startup. The 16 MiB development native-kernel rebuild
session (`build/i386-c2-managed-refresh-native-kernel`) has the same terminal
allocation/failure markers; its last harness checkpoint names the first kernel
build command, but that alone does not prove command execution began. Neither
installation nor a new native generation is qualified by this attempt. Diagnose
these startup/resource failures before claiming current-source minimal-profile
or native-release regression coverage. Earlier qualified generations remain
historical evidence, not substitutes for this image.
