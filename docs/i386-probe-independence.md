# Normal boot without diagnostic modules

The normal-boot isolation helper corrupts the first magic byte of both
CompilerProbe.t32m and CompilerProgramRuntimeProbe.t32m on a disposable copy.
It must still reach the actual normal welcome, execute 6*7 as 42 and report a
live code heap. It does not replace startup source or load a diagnostic stub.

The combined publication/Help full gate in the experimental answer-break
worktree completed all 526 interactive commands (589 submitted input lines),
with exact VGA at every checkpoint, the independent pointer oracle, Help
interaction, navigation, editing and 20 exact-heap document development cycles.
Its authoritative report is
`build/i386-publication-help-gate-minimal-v1/input/result.json` in that worktree.
The 8 MiB TCG/486 startup took 72.492 seconds, exceeding the 60-second profile.
The complete gate remains a failure: it subsequently stopped in
verify_normal_without_probe, before later source/rejection/install checks.

That helper requested a plain initial screen even though normal startup renders
the welcome document. The captured failing frame exactly equals all 307,200
pixels of the existing cursor-on welcome oracle. Its failed result, logs,
images and frozen builder/helper/font sources remain preserved in the gate's
failure.json. This was an expectation mismatch, not execution of the deliberately
corrupt diagnostic modules. The caller now explicitly requests the normal
welcome oracle; no raster comparison or workload assertion is removed.

`tools/test-i386-probe-independence.py` executes that actual shared builder
helper. It validates the source filesystem, independently locates the two module
magic bytes, and verifies that only those two bytes differ in the disposable
image. The focused 8 MiB TCG/486 run passes both commands and exact initial and
command pixels, with unchanged input hashes, in
`build/i386-probe-independence-welcome-v1/result.json` in the primary checkout.
It uses the recorded experimental gate image, not the primary runtime image.
Startup took 77.884 seconds; this is not a 60-second or complete-gate pass.
C1-C5 and inventory qualification remain open.
