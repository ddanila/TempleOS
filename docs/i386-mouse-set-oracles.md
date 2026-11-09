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

Native implementation and comparison are in progress. These workflows do not
qualify all pending-packet orderings, arbitrary settings, missing-device behavior,
`ms_hard`, complete window interactions, raster/resource limits or C1–C5.
