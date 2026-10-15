# Native Refresh and manager-iteration accounting

Console interface version 87 exports the shared public `Refresh` function and
`winmgr` state. The private 48-byte console service table, public CTask layout
and Memory interface version 25 are unchanged. The console's public export table
now has 228 entries: `_REFRESH` and `_WINMGR_STATE` follow the previous 226.

## Wait and frame lifetimes

The native Refresh scope registers before modifying task/document state. It
borrows the selected put document's memory owner and document identity, so DocDel
or owner retirement cancels the waiter before freeing that storage. Ordinary
return and exceptions share the repaired original cleanup; committed Exit drains
the same resource scope. A null put document is valid and still gets task-idle
restoration. The shared core uses the native jiffy reader and resident Sleep
provider through hooks; the original system retains its own clock and Sleep.

The actual manager sets REFRESH_IN_PROGRESS only after acquiring its frame lease
and validating admission. Graphics-scope release clears the flag on normal
return, exceptions, cancellation and actual worker death. A waiting request does
not claim that a frame has begun. Explicit/raw application presenters do not set
this manager-frame flag.

## Cadence and counters

`winmgr.updates` now counts completed manager iterations, rather than every raw
or explicit upload. The manager completes a custom graphics/document frame or
passes the focused ordinary view through the validated retained-terminal path.
The latter revalidates focus/task identity after waiting for the lease and
borrows the selected terminal owner. A matching retained image with no dirty
rows completes that path without an unnecessary VGA upload; an image mismatch
forces restoration. Counter advancement follows successful completion, not a
standalone timer tick or application-side increment.

Actual raw/graphics uploads maintain a separate private presentation epoch.
Manager FPS is measured from completed iterations. The nominal worker delay is
33 ms; this does not establish a measured 30 fps release profile. JUST_PUMP_MSGS
is consumed without completing a frame; that iteration yields before continuing.
The existing keyboard service remains independent. Complete original mouse,
control and event-pump semantics are still desktop integration work.

The retained ordinary-view path is an intermediate bridge. It does not run the
full original put-document/persistent-graphics/final-screen composition. Passing
ordinary-view wait/count checks does not qualify those visual effects, normal
stdout/input/Adam roles or all original applications. Custom shown-document
composition remains separately covered by actual pixel observations.

## Executable gates

```
python3 tools/test-i386-refresh-modes.py IMAGE --out OUT
python3 tools/test-i386-refresh-document.py IMAGE --out OUT
python3 tools/test-i386-refresh-wait-lifetime.py IMAGE --out OUT
python3 tools/test-i386-refresh-frame.py IMAGE --out OUT
```

The modes fixture runs normal boot with WinMgr enabled, matching six original
ordinary-return cases. A separate isolated check temporarily suspends the manager
and requires raw/explicit uploads to leave its update count unchanged. The visual
gate uses Refresh(2) for two A/B phases, requires at least two tag evaluations per
phase, checks independent glyph pixels and continues with arithmetic afterward.

The lifetime fixture pauses WinMgr to hold two-frame waits deterministically.
Four mask-63 cases cover a recovered abort, forced Exit, explicit DocDel and the
document memory owner's retirement. Observations precede cleanup, with exact
parent heap and graphics/text presentation reuse. The forced-Exit case observes
the surviving document's restored flag; it does not read a retired task's flags.

The frame fixture briefly resumes the actual manager with a custom shown view
and holds its final-screen callback. An independent zero-count waiter must stay
idle and blocked until that frame completes or the manager terminates. Its death
case clears the one-shot callback and exits the actual manager; synchronization
must unblock and supervision must create a new manager that completes another
iteration. Both cases require released in-progress state, exact parent heap and
presentation reuse. The original frame/abort oracle and shared-core controls are
recorded in [Refresh contract](i386-refresh-contract.md).

The first modes prototype stopped at `&DocPut->flags`: the native parser rejects
that shorthand in this argument context. The final modes fixture uses the same
local-document-pointer form as the pinned original baseline. This is an open C4
compiler-expression gap, not a passing test of that syntax.

## Remaining acceptance

Qualify pump-event consumption/order, raw/debug/focus transitions with held
frames, document replacement during waits and the complete ordinary-view
composition/input roles. Continue differential API/DolDoc and application tests.
The first visual Refresh gate is an integration step, not complete C2/C4 or C5.
C1–C5 remain open.

## Final-image evidence (2026-10-15)

The candidate is `build/i386-c2-native-refresh-cross-clock/kernel.img`.
Original self-rebuild, cross-build and the 386 boot instruction audit pass. All
1473 recorded source/build inputs match. QEMU runtime checks use 486,-fpu.

| Result under build/ | Commands/submissions | Result |
| --- | --- | --- |
| i386-c2-native-refresh-modes-local/result.json | 15: six original modes plus upload-count isolation | pass |
| i386-c2-native-refresh-document/result.json | 9: two Refresh(2) A/B glyph phases and continued input | pass |
| i386-c2-native-refresh-wait-lifetime/result.json | 18: four mask-63 wait/retirement cases | pass |
| i386-c2-native-refresh-frame-final/result.json | 14: held-frame return and actual manager death/restart, both mask 63 | pass |
| i386-c2-native-refresh-startup/result.json | 9 at 8 MiB, 48.95 seconds, no build providers, manager enabled | pass |
| i386-c2-native-refresh-worker/result.json | 14 existing worker lifecycle commands | pass |
| i386-c2-native-refresh-error/result.json | 14 existing error/report/cooldown commands | pass |
| i386-c2-native-refresh-window-update/result.json | 48 existing whole-window commands | pass |
| i386-c2-native-refresh-frames/result.json | 24 window/graphics/text-frame submissions at 64 MiB, including pause setup | pass |

All custom fixture reports retain unchanged pinned inputs. The final modes
checker fails on the old Console-86 image in
`build/i386-c2-refresh-modes-red-final/result.json`, with unchanged inputs: the
public state/API cannot compile, so its functional mode assertions are
unexecuted there. The earlier committed visual gate similarly rejects missing
Refresh before either A/B observation.

The clock-hook revision retains the original-system control results in
`build/i386-c4-refresh-native-clock-modes/result.json` (six original mode masks)
and `build/i386-c4-refresh-native-clock-lifetime/result.json` ([15,0] after the
cleanup repair). Both controls retain unchanged inputs.

The first two native cross-build attempts exposed unsupported loop control and
a missing console-local clock adapter. Neither generated a qualified image;
the final clock-hook image above is authoritative. The long development native
flat-kernel run remains on its older pinned Console-86 source image, outside
this cross-built API qualification and outside full C5 acceptance.
