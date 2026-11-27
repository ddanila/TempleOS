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

A finer trace bounds the VGA buffer fill at one 10 ms timer tick in the
baseline record redraw. The initial formatted document output takes 240 ms,
followed later by 270 ms between the picker draw and the first toolbar button.
A disposable overlay uses the 386 `REP STOSB` instruction for the public byte
fill. Both versions pass the focused fill contract for five unaligned
307,200-byte fills, low-byte truncation, zero and negative counts, end pointers,
and untouched boundary bytes. The baseline takes one 10 ms guest tick for the
five fills. The overlay finishes within a tick. The overlay still records a
zero-duration first note and spends 1,050 ms in record redraw, within the range
of the previous baseline measurements. The fill is outside the dominant
redraw cost. See `build/psalmody-redraw-profile-v2` and
`build/psalmody-native-memset-v1`.

A ConsoleRuntime experiment suppresses the nested `DocPutKey` yield when its
caller already owns the document lock. The overlay cross-build and instruction
audit pass. With the original application bytes and original physical input
sequence, native durations are 0, 8, 8. A separate profiled run measures the
record redraw at 1,020 ms, including 720 ms before the final refresh. The
experiment leaves the first-note failure in place. The disposable patch and
receipts are in `build/psalmody-doc-stream-batch-v1` and
`build/psalmody-redraw-profile-v2/batch64`.

With the stock document scheduling policy, a native-only trace around the
record menu's first styled string measures 160 ms inside the document update
and another 90 ms in the final yield. The formatter has already produced the
string at the start of this measured interval. Lock acquisition and release
each take less than one 10 ms tick. This separates the stream update from
waiting on the document lock. See `build/psalmody-doc-stream-trace-v2`.

The changed-row VGA overlay keeps the native framebuffer layout and retains
a full upload when the display changes backing surfaces. Its profiled redraw
takes 700 ms, including 200 ms in the last two-frame wait. The corresponding
full-upload run took 1,150 ms and 290 ms. The first recorded note still has
duration zero with the strict original input sequence. The overlay, pending
separate raster verification, remains a disposable candidate. See
`build/native-graphics-dirty-rows-v1` and
`build/psalmody-redraw-profile-v2/dirty64`.

After the record redraw has settled, the changed-row overlay passes the exact
keyboard comparison with the unchanged Psalmody application. It records
durations 8, 8, 8, deletes the last note, restores the caller state, and matches
all three original binary records. Fresh arithmetic renders correctly and
all 1,903 pre-existing filesystem entries are preserved. The original fixture
still sends the same 400 ms holds. The immediate-input test still fails, so
the passing case covers typing after the recording UI is ready. See
`build/native-graphics-dirty-rows-v1/psalmody-ready64/result.json`.

Changed-row and full VGA uploads match all pixels in four native persistent
graphics frames. A direct red bitmap pixel appears, a green final hook
covers it, removing that hook reveals a blue pixel, and clearing the bitmap
restores the white document. Both sessions execute fresh arithmetic.
The raster harness and receipt are in
`build/native-graphics-dirty-rows-v1/raster-compare-v2`. Raw VGA writes and
forced display flushes are separate transitions under test in the next overlay.

The nested-yield experiment passes the five explicit document-stream checks
when packaged as a guest fixture. These cover partial markup, escaped dollar
signs, plain-text output and middle insertion. The older terminal harness
timed out at its startup raster before it reached the checks. The packaged
runner verifies the five conditions directly and renders fresh arithmetic.
The receipt is in `build/psalmody-doc-stream-batch-v1/stream64-packaged`.

The second changed-row overlay also invalidates its VGA cache after raw
character output and honors a requested full VGA flush. It matches the full
upload in all six native raster comparisons. Both raw-output restoration
and explicit flush restore the same RGB bytes as the initial frame.
The unchanged Psalmody keyboard workflow after the redraw independently
passes a second time with durations 8, 8, 8. These results are mapped to
the Psalmody loader and application source in the compatibility inventory.
The candidate and receipts are in `build/native-graphics-dirty-rows-v2`.

The second changed-row overlay passes the 8 MiB production User startup check
with the managed pointer and five command/raster checkpoints. Its startup took
50.85 seconds and passed the existing 60-second budget checker. The
`user8` receipts under `build/native-graphics-dirty-rows-v2` cover the production
User path. The separate original User startup gate remains open.

The 32-bit planar converter matches eight full-upload raster checkpoints,
including a mixed pattern that displays all 16 palette colors. Its profiled
record-menu redraw takes 740 ms, compared with 700 ms in the changed-row
control. The immediate-input sequence still records 0, 8, 8. This single
comparison shows no further redraw improvement. The disposable patch,
raster receipt and timing comparison are in `build/native-graphics-pack32-v3`.

The early public SwapI64 binding, shared registry popup, and changed-row
VGA upload are integrated. MemoryRuntime is version 42 and ConsoleRuntime
is version 275. Two original bootstrap rebuilds and the standard native
cross-build pass, with 1,532 delivered files audited against the integrated
source. The integrated image verifies signed 64-bit and same-address swaps
at 8 MiB, registry popup cancellation and cold suppression, and all six
changed-row raster comparisons. Psalmody matches the original binary
records after the record menu has settled. Production User startup passes
the 60-second budget at 50.52 seconds. The integrated build and receipts are
in `build/i386-graphics-registry-integration`.

Immediate input during the redraw remains a timing gap. The earlier
two-generation rebuild receipts refer to their own pinned production sources.
The integrated source needs its own two native generations and the remaining
desktop and application qualification.

## Immediate keyboard recording with queued timestamps

The timing overlay uses the native keyboard queue's arrival jiffies when
both ends of a note have ordered physical timestamps. It keeps the
existing dispatch-clock calculation for the original system and messages
without arrival timestamps. The immediate-input test uses the unchanged
physical 400 ms holds and sends the first note as soon as the record flag
changes. The patched original and native runs both produce durations
8, 8 and 8, an exact post-backspace record, and caller mask 63. The native
filesystem preserves all 1,904 existing entries and fresh arithmetic
renders. See `build/psalmody-arrival-duration-v1`. The unchanged-source
control on the same image is running. Production integration and the
default runner's source verification still need updating.

The unchanged-source control on the same menu/focus image reproduced
durations 0, 8 and 8. The timestamp change is now integrated, and the
standard source-checked runner accepts its reviewed file digest alongside
the archived original. The full production image passes the immediate
400 ms input sequence with exact original note, deletion and caller-state
records. See
`build/native-focus-menu-psalmody-production-v1/psalmody64/result.json`.

## Staccato serialization

The save mismatch is reproducible without loading Psalmody. At slider
position 71, the original compiles `0.88`, `0.12` and `0.0005` to
`3FEC28F5C28F5C2A`, `3FBEB851EB851EBA` and `3F40624DD2F1A9FE`. The
i386 compiler uses `3FEC28F5C28F5C29`, `3FBEB851EB851EB8` and
`3F40624DD2F1A9FC`. After applying the bias and scaling by 1000, the
original is one binary64 step above 901.5 and i386 is one step below.
[Original probe](../build/i386-psalmody-staccato-v2/original.txt) ·
[i386 probe](../build/i386-psalmody-staccato-v2/native.txt)

Across the 80 slider positions admitted by Psalmody, 22 formatted values
differ. Substituting the original literal bits matches the default
position but produces 26 mismatches over the same range. The sweep
captures position 80 as an extra endpoint and excludes it from both
counts. This experiment leaves the app source and strict persistence
oracle intact.
[Original sweep](../build/i386-psalmody-staccato-v3/original.txt) ·
[i386 sweep](../build/i386-psalmody-staccato-v3/native.txt)

The next probe captures the actual formatter scale, `Pow10I64(3)`. The
original uses `408F3FFFFFFFFFFF` and i386 uses `408F400000000000`, exactly
1000. A rational-arithmetic check reproduces the factor, biased value,
scaled value, rounded integer and formatted text for both guest traces
at all 80 slider positions. The original path uses 64-bit significands
for the factor expression and binary64 for the stored factor and the
subsequent operations. For this finite slider range, evaluating the
factor as an exact rational and rounding once to binary64 gives the same
results. The earlier multiplication by literal 1000 was a diagnostic
and differs from the scale used inside the original formatter.
[Trace and model](../build/i386-psalmody-staccato-v4/check.py)
