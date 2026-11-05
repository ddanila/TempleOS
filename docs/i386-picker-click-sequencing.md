# Mouse picker input sequencing

The complete minimal TCG gate at
`build/i386-welcome-keyboard-gate-minimal-v1` terminated at `mouse-picker-select`.
The picker selected Two.HC and its exact selected frame passed, but the next
back-to-back left-button press/release did not produce another selection marker.
The terminal `failure.json` pins the source, image, log, screenshots and
checkpoint, with verified frozen copies of the host helper, builder and picker
runtime. This run passed earlier compiler, document and mouse-editing stages;
it is not a complete gate pass.

`MouseGet` snapshots the current hardware button state. It does not queue every
button edge. A host press immediately followed by release can therefore leave
only the released state when the scheduled picker polls. The test now holds a
press until the picker acknowledges selection/activation. A diagnostic release
marker confirms that the picker has consumed release before another press. The
runtime marker does not change selection, click timing, drawing or public APIs.

`tools/test-i386-mouse-picker-clicks.py` extracts the existing five-command picker
workflow and interaction from the selected host helper, then drives it through
physical QMP input. It retains every visible expectation: select the second file,
double-click into its editor, inspect the exact buffer, exit and inspect the
picker again. It also checks subsequent compilation. It uses 8 MiB and a 486
without FPU with live WinMgr. An explicit `--runner` selects a frozen baseline
without mutating a running helper.

The baseline helper passes the isolated TCG workflow in
`build/i386-mouse-picker-clicks-red-v1/result.json`, despite that output directory's
historical name. The full-run failure is intermittent; the isolated result is
retained as a pass. It is not evidence of a consistently failing runtime defect.
The acknowledgement change passes the complete isolated workflow on both TCG
and KVM in `build/i386-mouse-picker-clicks-sync-tcg-v1/result.json` and
`build/i386-mouse-picker-clicks-sync-kvm-v1/result.json`, with unchanged image,
runner and driver inputs. Both
original bootstrap generations, the 386 instruction audit, and all 1,361
packaged source/document comparisons pass for `build/i386-mouse-picker-sync-v1`.
These prerequisites do not replace a complete minimal gate.

The fresh full minimal gate at `build/i386-picker-ack-gate-minimal-v1` has passed
the previously failing picker stage and advanced into file navigation. Its
`input/picker-stage-pass.json` pins the six completed selection/open/editor/return
frames, helper hash and next authoritative checkpoint. The run has now ended
with a timeout in the later `mouse-help-link` interaction, after capturing its
initial and selected frames. `failure.json` pins the terminal checkpoint, logs,
image, frames and frozen runner/source copies. The picker fix passed inside the
full workload, but the complete minimal gate and original desktop qualification
remain open. The Help interaction failure needs investigation.

The later Help timeout now has a consumed-release acknowledgement fix and fresh
isolated TCG/KVM passes; see [Help click sequencing](i386-help-click-sequencing.md).
The full workload still requires another run.
