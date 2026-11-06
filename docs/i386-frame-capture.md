# Frame-capture bitmap and GR dependencies

`tools/test-i386-frame-capture.py` uses an 8-by-4 bitmap with bytes 0 through
31, an identity matrix and a separate depth buffer. Its twelve checks cover
independent copies, unchanged-image diff, exact one-pixel and rectangular diff
bounds/pixels, compressed save/load, and real GR file write/read.

The uncompressed export must equal an independently constructed 32-byte header
(`<q6i`: timestamp 0x0102030405060708, origin -2/5, dimensions 8/8/4, flags zero)
followed by bytes 0 through 31. The file must match those bytes, and its reload
must retain the timestamp, origin, dimensions and pixels.

`build/i386-frame-capture-original-v1/result.json` passes all twelve checks and
both byte exports with unchanged inputs. The interface-222 native image fails
at the first DCCopy call (fixture line 10), before any behavior assertions run,
in `build/i386-frame-capture-native-v1/result.json`; inputs are unchanged.

These dependencies are required by screencast frame recording. Actual screen
composition/capture timing, frame sequences, all allocation-failure cleanup and
complete screencast behavior remain unqualified.

```
python3 tools/test-i386-frame-capture.py --out OUT_ORIGINAL
python3 tools/test-i386-frame-capture.py IMAGE --out OUT_NATIVE
```

## Native provider qualification in progress

Interface 223 shares the original DCCopy, DCSave, GRWrite, DCExt and DCDiff
bodies. The original-path byte comparison passes for all four extracted cores
in `build/i386-frame-capture-source-parity-v2.json`. As with GrRect, the native
provider requires an explicit DCExt context because the cross-compiler cannot
fold `gr.dc`; the public declaration retains its original default. The first
cross-build exposed a missing MemCmp import, and the second exposed that
nonconstant default. Both failures remain preserved.

Both bootstrap generations pass in `build/rebuild-test/result.json` for v3.
The v3 cross-build exported its modules and produced the candidate image;
its full 8 MiB diagnostic suite fails after phase-one DISK READ while allocating
decompression workspace. The instruction audit passes 96
BIOS and 332 protected-mode instructions. The post-export source audit matches
all 1,721 bootstrap input hashes.

`build/i386-frame-capture-native-v2/result.json` passes all twelve checks,
both exact exports and subsequent arithmetic, with unchanged inputs, using
`build/i386-frame-capture-cross-v3/kernel.img`. This is bitmap/GR dependency
qualification only. Actual compositor recording and failure cleanup remain
open. `build/i386-frame-capture-welcome-screen-v1/result.json` passes exact
welcome pixels, suspended clear and input at 8 MiB TCG with unchanged inputs.

The full diagnostic failure is preserved in `build/frame-capture-cross-v3.log`
and `build/i386-frame-capture-cross-v3/boot/debug.log`. The rejected allocation
is 0x1008c bytes. Module-symbol resolution identifies callers I386ArcCtrlNew
and I386ExpandBuf. The previous interface-222 diagnostic image fails at the same allocation and
step, with its image hash unchanged. See
`build/i386-frame-capture-diagnostic-comparison-v1.json`.

The stopped-heap capture in
`build/i386-frame-capture-diagnostic-heap-v1/result.json` confirms the failure
with unchanged inputs: capacity 6,791,680 bytes, used 6,718,376 bytes, and largest
free block 43,136 bytes. Although 73,304 bytes remain free in total, no block
can satisfy the 65,676-byte request. Fragmentation and limited remaining
capacity therefore both constrain this diagnostic. This does not qualify the
complete 8 MiB suite; a memory-lifetime/allocation fix remains open.

The separately launched TimeClock test in
`build/i386-frame-capture-welcome-v1/result.json` fails before application
execution: this minimal image contains neither `/Apps/TimeClock/Load.HC` nor
its compressed counterpart. Its input audit passes. That result does not
qualify TimeClock or the welcome pixels.
