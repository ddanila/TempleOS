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
