# Original MsSet reference workflows

`tools/test-i386-mouse-set.py` compares sixteen immediate/settled phases of the
original public `MsSet` API: omitted arguments, invalid x/y and button values,
scale/offset conversion, snapping, non-unit grid speed quantization, synthetic
buttons across keyboard input, and physical movement/wheel/button follow-up.
The fixture also checks caller document/geometry/inhibit/heap/position recovery.
It records 32 rows of 17 values; it does not measure mouse velocity or timing.

- `build/mouse-set-original-v1`: pinned original passes all phases and mask 7.
- `build/mouse-set-audit-v1/model.py`: independent numerical/default/button model
  matches all 544 values, including immediate versus settled quantization.
- `build/mouse-set-current-classic-v1`: source-pinned two-generation classic
  rebuild produces identical rows and mask. This is additional classic
  verification, not a C5 native self-hosting generation.
- `build/mouse-set-native-before-v1`: unchanged delivered wheel image fails
  fixture compilation at the first `GridInit` call. Its public mouse header and
  runtime also lack a native `MsSet` binding. No MsSet phases execute in this
  strict baseline failure.

`tools/test-i386-mouse-set-controls.py` exercises synthetic control delivery
without injecting physical mouse input. Nine phases cover separate left/right
press/release, a transient press/reset before WinMgr can run, moving outside
and back during that transient state, and simultaneous left/right transitions.
Yielding callbacks record window-relative coordinates, owner/task/IRQ identity;
the caller also verifies that MsSet preserves a cleared IF bit.

- `build/mouse-set-controls-original-v1`: retained failed *test expectation*.
  The prototype expected control-relative (12,12) and both callbacks for
  simultaneous button changes. The original delivers window-relative (52,42)
  and only the left callback for the simultaneous transitions in this workflow.
- `build/mouse-set-controls-original-v2`: corrected strict original oracle passes
  nine rows, six callbacks and restoration/IRQ mask 7. The coordinate rule
  follows WinMgr's subtraction of `task->pix_left/top`; the simultaneous rule
  follows its first left-control callback jumping to `wmt_start`, with the
  shared message recognizer copying both button values into the old state.

The native implementation and comparisons are recorded in
[the implementation record](i386-mouse-set.md). These workflows do not
qualify all pending-packet orderings, arbitrary settings, missing-device behavior,
`ms_hard`, complete window interactions, raster/resource limits or C1–C5.

## Public message delivery and pending-state probes

`tools/test-i386-mouse-set-messages.py` adds eight phases that collect actual
`ScanMsg` move/button records before the keyboard barrier. It checks no-op and
transient set/reset behavior, exact window coordinates, requested/actual raw
mode, IF preservation and caller/heap recovery. No physical mouse events are
injected. Both `mouse-set-messages-original-v1` and
`mouse-set-messages-raw-original-v1` pass with the same six messages and mask 7.

On candidate `i386-mouse-set-cross-v2`, the state, corrected control-priority and
managed message workflows pass (`mouse-set-native-v2`,
`mouse-set-controls-native-v2`, `mouse-set-messages-native-v2`). The raw message
workflow remains a strict zero-message failure in
`mouse-set-messages-raw-native-v2`, despite correct public position/buttons.
The earlier v1 control candidate retains its strict eight-versus-six callback
failure. The v3 candidate adds raw message delivery; both managed and raw comparisons
now pass as recorded in the implementation record.

`tools/test-i386-mouse-set-queue.py` compiles the exact delivered native
`MsHardSet` source into isolated state with clock/init stubs. Fixed numerical
cases check wrapped pending-packet rebasing, repeated synthetic sets, metadata
and guard preservation, fractional grid speed and clipping. A separate real
`MsSet` call checks unchanged raw `MouseGet`, logical position/button/keyboard
state, masked IF restoration and exact caller heap. `mouse-set-queue-v2` passes
mask 63 and a fresh 42 with unchanged files/inputs. This is not a live pending
IRQ-interleaving test. `mouse-set-current-classic-v3` also matches the original
544 values on the latest source-pinned classic bootstrap.


The final state oracle also records the two mouse-button bits returned directly
through `ScanKey` at every phase. `mouse-set-original-v2`,
`mouse-set-current-classic-v4` and `mouse-set-native-v4` match all 544 state
values and these 32 delivered key-button values, with mask 7. The original v1
and earlier native/classic captures remain valid state-only evidence with their
archived fixtures/runners. See the implementation record for final regressions
and current failed console/editor gates.
