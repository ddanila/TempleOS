# Native graphics frame presentation

Normal native startup now creates the original `gr.dc` persistent overlay and
`gr.dc2` working surface at 640 by 480, with packed 8-bit pixels. The persistent
surface starts transparent and carries the original screen/on-top flags. The
working surface carries the original screen flag. `gr.text_base` points to the
existing native text-cell surface, and screen zoom starts at one.

This is the framebuffer/presentation boundary for subsequent original DolDoc
integration. It does not install the complete original window manager, sprite
renderer or document handlers. The ordinary command console remains the input
interface.

`NativeGraphicsPresent(draw, blink)` preserves the original ordering:

1. Render all text backgrounds, then foregrounds.
2. Invoke the supplied task-drawing callback with an alias of `gr.dc2`.
3. Composite the persistent `gr.dc` through the original `DCBlotColor8` routine.
4. Invoke `gr.fp_final_scrn_update`, if set, with an on-top alias.
5. Convert the finished surface to VGA planes and upload it.

Text panning is clamped to the original -7 through 7 range. The presenter retains its own 153600-byte plane buffer, preserving the ordinary
console's pixel storage and avoiding conversion-buffer allocations per frame. Aliases and their matrices are temporary; exception cleanup
releases them and clears the presentation guard before rethrowing. Recursive
presentation and calls by another task are rejected. Keyboard/timer interrupts
remain enabled during frame composition and upload.

The console task owns both persistent contexts for its lifetime. Repeated
`NativeGraphicsStart` calls validate and reuse them. Initialization publishes
neither context until both contexts and the conversion buffer are allocated. Shared `DCNew` and `DCAlias`
now clean up partial construction if allocation throws, preserving the original
successful-operation behavior.

## Manual demonstration

On a normal native QEMU boot:

```c
#include "/Kernel/I386/GraphicsFrameDemo.HC"
GraphicsFrameDemo(0);
```

Modes 0 through 3 exercise blink and text panning. The screen combines text,
a task-drawn rectangle, a partly transparent persistent overlay and a final
cross-shaped overlay. Press Ctrl-Alt-C to return to the prompt. The demo restores
the prior text cells, persistent pixels, pan/hide settings and final callback,
and returns 1 when its allocations have been reclaimed.

The demo records frame duration in `graphics_frame_ticks` (1000 jiffies/second)
and its temporary heap footprint at the draw callback in
`graphics_frame_heap_bytes`. These are component measurements, not end-to-end
editor input-latency or whole-OS peak-memory acceptance.

## Verification design

The x64 oracle compares twelve blink/pan/hide combinations with the original
text-rendering and composition sequence. It independently decodes all four
output planes and checks conversion-buffer guards. The native QEMU harness
compares four complete RGB frames against a separate Python oracle and interrupts
each demo back to the prompt. Additional checks cover repeated initialization,
callback exceptions, subsequent presentation, pan clamping and failed large
context allocation followed by successful allocation, with heap reclamation.

Both original x64 rebuild/reboot generations and the full native suite pass.
The complete run executes 214 commands / 277 lines, including four composed
graphics frames, four existing text-only frames, five callback/recovery groups,
two allocation-recovery groups, and the prior context/calendar/math checks.
Startup recovery, diagnostic independence and all 17 module rejections pass.
All 1176 OS source hashes, 20 build-input hashes and both disk hashes match.

The persistent contexts and graphics planes consume 1314792 heap bytes including
allocator rounding and headers, versus 768000 bytes of pixel/plane payload.
ConsoleRuntime 22 retains 241304 bytes, 9592 bytes more than version 21. The
kernel remains 366496 bytes, leaving 22624 bytes of bootstrap headroom.

On the QEMU 486 / 8 MiB profile, normal boot measured 35.121 seconds and separate
diagnostics 152.385 seconds. The four full demo frames measured 480, 490, 480
and 490 jiffies; each used 545256 temporary heap bytes at the draw callback and
reclaimed them on interruption. The packed plane conversion uses four masked
64-bit multiplies per eight pixels; original/native pixel checks cover it.
The verified normal preview is refreshed.

Full-frame presentation is still roughly half a second in this demonstration.
Incremental redraw and actual editor input latency need work and measurement
during document integration. The usable native editing-session goal remains open.
