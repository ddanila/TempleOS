# Diagnostic startup display readiness

The full gate previously captured VGA immediately on `DONE native kernel
startup`, then compared it with an old four-line console. That marker can
precede the first complete WinMgr frame: the failing capture has a transitional
blue palette and no prompt. The delivered desktop includes the original welcome
document, so even a completed frame differs from the old expectation.

The generic guest runner now has an opt-in `--native-welcome` mode for i386 disk
runs. After the exact native-startup completion marker, it waits at most thirty
seconds for a complete 640x480 welcome raster and prompt. FAIL lines remain
fatal; other completion markers are rejected in this mode. Other guests retain
their existing DONE handling. The full diagnostic gate requests this mode and
independently checks the saved raster against the same expected variants.

The oracle constructs expected pixels from explicit welcome text, original font,
standard palette, heading/link colors and underlines. Every one of the 307,200
pixels must match; only two exact cursor-on/off frames are accepted. It does not
mask regions or derive expected pixels from the observed guest image. Shared
startup row construction keeps this expectation aligned with the existing
interactive welcome checker. `screen-oracle.json` records the matched variant,
pixel count and raster hash.

## Verification

- `build/i386-welcome-oracle-check-v1.json`: accepts all three saved native
  registry-workflow initial frames; rejects the prior transitional capture,
  obsolete plain console and a single-pixel mutation of either valid variant.
- `build/i386-native-welcome-runner-v1`: a normal 8 MiB TCG boot passes the new
  wait with the exact cursor-on frame, with source/image/display provenance.
- `build/i386-welcome-gate-minimal-v1/boot/screen-oracle.json`: the complete
  diagnostic startup also passes all 307,200 pixels. Exact diagnostic-disk
  immutability still passes. The 1,361-file delivered-source audit passes, and
  all sixteen compiled module files match the preceding registry candidate.
  No production runtime code or resource budget changes.

The complete full gate remains **fail** in the following normal keyboard
runner. That separate call still requests the obsolete four-line console and
times out before submitting any commands. Its actual initial frame exactly
matches the complete welcome oracle; expected rows, actual frame, terminal log
and hashes are preserved in
`build/i386-welcome-gate-minimal-v1/failure.json`. Its keyboard and later
regression coverage is not yet qualified. Updating that session must retain its
existing workload and checks. Complete minimal regressions and C1-C5 remain open.
