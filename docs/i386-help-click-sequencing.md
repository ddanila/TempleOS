# Help-link click sequencing

The full minimal run at `build/i386-picker-ack-gate-minimal-v1` passed its
acknowledged picker workflow, then timed out during `mouse-help-link` after the
first selected frame. Its frozen failure record preserves the image, source,
runner, terminal checkpoint and initial/selected frames.

The Help view now logs a consumed left-button release, like the file picker.
The host waits for each selected press before releasing, and for each consumed
release before sending the next press. On activation it also waits for the
nested Help view to begin before releasing. The three clicks, coordinates,
0.6-second first-click separation, target page, return operation and expected
frames remain unchanged. The guest addition observes existing mouse state;
it does not replace selection or activation behavior.

`tools/test-i386-mouse-help-clicks.py` extracts the actual full-suite interaction
and its expected rows from the shared runner. Both
`build/i386-help-click-release-tcg-v2/result.json` and
`build/i386-help-click-release-kvm-v2/result.json` pass at 8 MiB, 486 without FPU
with live WinMgr and unchanged inputs. All six initial/selected/opened/returned/
editor-style-final/console-return frames match exactly, as do the setup and
arithmetic recovery commands. Startup is 71.942 seconds on TCG and 33.228 on
KVM; this does not pass the 60-second TCG startup gate.

The first isolated v1 guests completed their exact-pixel workflows, but the new
driver then failed to serialize tuple coordinate keys in its report metadata.
Their failure records retain that distinction. The corrected reporter converts
only its metadata copy; the actual gesture and color dictionaries remain intact.
The fresh v2 outer reports pass, rather than relabeling the earlier runs.

Both original bootstrap generations, the 386 instruction audit, and all 1,361
packaged source/document comparisons pass for the candidate. The complete full
workload still needs a fresh run; isolated Help/picker passes do not qualify the
whole desktop or C1–C5.
