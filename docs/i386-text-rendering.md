# Native text-layer presentation

The retained ConsoleRuntime exposes `NativeTextBasePresent` and
`NativeTextBaseRestore`. The former composes the original 80 by 60 text-cell
surface and uploads all four VGA planes; the latter restores the ordinary
command console. This is a presentation dependency of the original document
renderer. Document layout, graphics/window composition, editor input and the
save/reboot/reopen workflow remain unfinished.

`Kernel/TextRenderCore.HC` implements the policies of `GrUpdateTextBG` and
`GrUpdateTextFG` on a packed 640 by 480 pixel surface. All backgrounds precede
all foregrounds. It preserves selection, inversion, blink phase, underline,
signed per-cell glyph offsets, screen panning and hidden final rows/columns.
The shifted-glyph clipping bound and packed offset arithmetic match the
original, including its strict upper bound. The original x64 renderer remains
unchanged as an independent reference. Arbitrary padded drawing contexts are
outside this presentation boundary.

The native wrapper converts the packed color indices to four VGA bitplanes
using the existing upload service. Its two temporary buffers contain 460800
bytes, excluding allocator overhead. They are freed before returning or
propagating an exception. The ordinary console planes and cursor are preserved.
This initial implementation redraws a whole frame; dirty regions and measured
interactive redraw latency remain work for editor integration. A hardware break
queued during this finite retained call is delivered at the next compiler
checkpoint after the call returns.

## Manual demonstration

Boot the normal preview with:

```sh
qemu-system-i386 -machine pc -accel tcg -cpu 486 -m 8 -nic none -snapshot \
  -drive file=build/TempleOS-i386-preview.img,format=raw,if=ide
```

At the HolyC prompt:

```c
#include "/Kernel/I386/TextFrameDemo.HC"
TextFrameDemo(0);
```

The screen shows a deterministic color/glyph pattern. Press Ctrl-Alt-C to
restore the console; the command returns 1 when temporary heap usage has been
fully reclaimed. Modes 1, 2 and 3 exercise the alternate blink phase and panning.
The demo also saves/restores the cell surface with a temporary 19200-byte copy.
It is a renderer demonstration, not yet an editable document. The snapshot
option discards disk changes on exit and is unsuitable for persistence testing.

## Verification design

The x64 oracle compares all 307200 pixel indices in 12 complete frames with
the original background/foreground renderer, using both blink phases and six
pan/hide configurations, including clamping. It saves/restores graphics globals,
font, clock and interrupt state around isolated non-yielding rendering calls.

The native keyboard suite executes four demo modes and compares complete VGA
screenshots against independently composed Python RGB frames using the original
font and QEMU's six-bit DAC expansion (the same conversion as the existing
VGA test). Each frame is captured before a hardware Ctrl-Alt-C; the suite then checks
heap reclamation and exact restoration of the command prompt. PNG captures are
written under `build/i386-kernel/input/text-frame-*-frame.png`.

## Validated result

Both x64 rebuild/reboot generations and the full QEMU/486 8 MiB native suite
pass. The 12 original-frame comparisons and four native VGA frames pass, as do
191 commands / 254 input lines, 11 hardware breaks, startup recovery and all 17
module rejection cases. All 1146 source hashes, 12 build-input hashes and both
disk hashes match the tested tree. The normal preview has been refreshed from
the verified image.

Normal startup measured 21.827 seconds; separate diagnostics took 134.773 seconds.
ConsoleRuntime 18 retains 181352 bytes (181336-byte image), an increase of 13328
bytes over version 17. Service/configuration records remain 32/32 bytes. Kernel
size is unchanged at 364864 bytes, leaving 24256 bytes of reserved-load headroom.
Temporary buffer sizes above exclude allocator overhead; a complete editor peak
memory and redraw-latency measurement is still outstanding. This evidence covers
QEMU's 486 profile, not strict 386 or physical-PC acceptance.
