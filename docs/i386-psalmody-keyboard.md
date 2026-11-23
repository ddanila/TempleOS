# Psalmody keyboard workflow

`tools/test-i386-psalmody-keyboard.py` loads the full original Psalmody source
and invokes `Psalmody`. A read-only observer waits for recording and note-list
transitions; QEMU sends `z`, holds `h`, `j`, and `k` for 0.4 seconds each,
presses Backspace, then Shift-Escape. The observer exports typed note vectors
and checks caller documents/form flag, draw callback, menu/settings, control
list and window bounds after the application returns.

The original control in `build/i386-psalmody-keyboard-reference-v1/result.json`
passes with unchanged inputs and restoration mask 63. The three notes have
pitch values 63, 65 and 67 (C5/D5/E5), type 1, duration index 8 and flags 0.
Backspace leaves the first two notes. Duration index 8 follows the original
`PsmCvtDuration` thresholds at the default tempo; the oracle preserves that
behavior. This is a timed keyboard test, so different timing environments may
require investigation rather than changing its expected data.

The native run in `build/i386-psalmody-keyboard-native-v1/result.json` verifies
all packaged Psalmody bytes against the pinned original inventory, then fails
while including the full `Load.HC`: `Invalid lval` at `SC_DELETE` in
`JukeBox.HC`, line 56. The fixture has not run at that point. Input hashes remain
unchanged. `SC_DELETE` is defined as 0x53 in `Kernel/ScanCodes.HH`; this result
identifies a public-header exposure frontier, not a successful native workflow.

Run the original control with a fresh output directory:

```
python3 tools/test-i386-psalmody-keyboard.py --out build/psalmody-reference
python3 tools/test-i386-psalmody-keyboard.py build/IMAGE/kernel.img \
  --reference build/psalmody-reference --out build/psalmody-native
```

The runner retains its source, fixture, screenshots, debug log and input hashes.
The native successful path additionally requires exact original vectors, all
preexisting file bytes/attributes/timestamps preserved, a clean filesystem and
fresh rendered arithmetic. Those native checks have not yet passed. Audio,
playback, saving/reopening, other editing operations and full application/C1–C5
qualification remain open. Included JukeBox and JukePuppet functions are not
claimed as exercised merely because the original loader compiled them.

## Provider diagnosis

Two disposable-image diagnostics isolate the next dependencies without altering
the application or the active native-build inputs:

* `build/i386-psalmody-header-probe-v1/result.json`: explicitly including the
  delivered shared `Kernel/ScanCodes.HH` succeeds, and `SC_DELETE==0x53` passes.
  The unchanged full Psalmody loader then rejects `GodWordStr` at JukeBox line
  91. `PublicKeyDev.HH` includes scan flags but omits scan codes; adding the
  shared scan-code include there is the pending normal-startup correction.
* `build/i386-psalmody-god-probe-v1/result.json`: the same setup plus original
  `Adam/God/GodExt.HC` loads successfully. Original `HolySpirit.HC` rejects
  `rev_bits_table` at line 58, before defining the required `GodWordStr` provider.
  The original kernel initializes this 256-byte bit-reversal lookup table;
  its public exposure and lifetime need integration before retrying that provider.

Both diagnostics preserve the authoritative source-image hash. They retain
scripts, logs and screenshots but are dependency probes, not new application
passes. The full nine-module C5 build is concurrently consuming pinned core
sources, so these probes use disposable images and do not change those inputs.

With the public-table, word-bitmap and signed-clamp candidate, the v4 God-provider
diagnostic loads all four original God files and verifies normal-startup scan
codes without a supplemental ScanCodes include. The full Psalmody loader then
stops at `FileOcc` in JukeBox line 135. See [signed-clamp evidence](i386-clamp-i64.md).
The app remains unqualified; the original keyboard control is still the target
workflow after these dependencies are restored.

## Guest timing comparison

A diagnostic overlay logs note onset and release timestamps inside Psalmody
on original TempleOS and the native registry-popup candidate. Both runs use
the same physical key sequence and exact note-vector check. The original
records guest intervals of 410, 400 and 400 ms and three duration values of 8.
The native run records intervals of 0, 430 and 310 ms and duration values of
0, 8 and 7. Host key holds were approximately 400 ms in both runs. Both runs
record the expected pitches, delete the final note and restore caller state.

The traces place the discrepancy before duration quantization. The next
comparison needs the queued input timestamps alongside the timestamps at
application dispatch to distinguish input delivery lag from elapsed clock
drift. The diagnostic scripts, receipts and decoded vectors are preserved
in `build/psalmody-timing-trace-v1`. The unchanged application's exact
keyboard acceptance remains open.

The native follow-up used the existing timed message scan in a disposable
Psalmody overlay to log the raw keyboard arrival and the application dispatch
clock. The first note's make and break arrived 400 ms apart (123861 and 124261
guest ms) and both reached Psalmody at 124851 ms. The next two pairs arrived
400 and 410 ms apart. The recording flag became observable while processing
`z`, before the application's record-menu redraw returned to its message loop.
The `z` release itself waited 1090 ms between arrival and dispatch. This
supports a dispatch delay for the zero-duration note, with a separate
40–90 ms delivery lag on later notes in this run. The trace keeps the original
400 ms injections and the exact duration check. The timed scan fixture,
receipt and decoded records are in `build/psalmody-timing-trace-v4`.

A second run waits for two window updates, completion of the full document
refresh, and the application's idle message wait before starting the same
physical 400 ms key holds. This run uses unchanged Psalmody sources on both
guests. The original still passes with durations 8, 8, 8. The native guest
records 7, 7, 8. Waiting for the record-menu redraw removes the zero in this
run but does not restore the exact keyboard contract.

A separate native profiling overlay measured the record-menu redraw at
1,050 guest ms. Clearing took 10 ms, drawing and inserting the first sprite
took 290 ms, and the remaining menu work took 450 ms. The final two-frame
refresh wait took another 300 ms. This identifies two costs to investigate
in the drawing and document paths and leaves the measured dispatch lag after
redraw open. The strict fixtures and receipts are in
`build/psalmody-redraw-gate-v1` and `build/psalmody-redraw-profile-v1`.

The same redraw instrumentation on original TempleOS passes the exact note
check. Its record-menu redraw takes 67 guest ms, with 5 ms before the final
refresh and 62 ms waiting for two frames. The native measurements at the same
markers are 750 ms and 300 ms. This puts most of the observed difference in
the work before the refresh. Both traces are in `build/psalmody-redraw-profile-v1`.
