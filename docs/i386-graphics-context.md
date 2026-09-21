# Original graphics device contexts on i386

Document recalculation uses device-context aliases for cursor location and
screen drawing, including sprite-bearing documents. ConsoleRuntime 21 now
retains the original context lifecycle and its default transform and lighting
callbacks. These are the 17 functions extracted byte-for-byte from the beginning
of `Adam/Gr/GrDC.HC` into `GrDCCore.HC`, through `DCDepthBufAlloc`.

Shared headers preserve the original geometry, color, device-context and graphics
global records. `CDC` keeps its 32-byte saved bitmap prefix independent of pointer
width. Its final size is rounded to eight bytes, as required by the original
record invariant; original x64 layout is unchanged. The standard palette is
shared verbatim with the original graphics implementation.

Native public declarations expose the retained functions, `gr` and
`gr_palette_std`. The global graphics record initially contains zeroes. This
step does not run the original graphics startup or install default framebuffers:
callers must supply a valid explicit context, or establish `gr.dc` before using
functions with a default context. Full framebuffer/window/sprite integration
remains required before document recalculation can draw the editor.

## Ownership and numerical behavior

`DCNew` allocates the context, pixel body and 32.32 rotation matrix on the selected
task's heap. `DCAlias` shares bitmap storage, allocates its own reset matrix and
copies the original context's other fields. As in the original implementation,
that includes the depth pointer: a caller borrowing an existing depth buffer
must detach it before deleting the alias. `DCDel` frees the matrix and depth
buffer and frees bitmap storage only for a non-alias context. The original
`DocRecalc` sprite path follows this convention: it detaches its temporary depth
buffer from the alias and frees that buffer separately after deleting the alias.

The native depth-reset fill is a U32 loop with the same count/value behavior as
the original memory primitive. Graphics lighting and matrix scaling import
software-F64 helpers from the retained CompilerRuntime; the console does not
contain another arithmetic implementation. CompilerRuntime 49 publishes its ten
existing arithmetic entry addresses alongside the 13 public numerical services,
using the same allocation-free, collision-checked binding operation. The console
currently imports five of those helpers.

## Verification

`GraphicsContextCheck` runs on both the original x64 environment and native HolyC.
Its 20 groups cover heap ownership and reclamation, width padding, initial pixels,
palette and matrix defaults, default-global routing, fill/clear, extents, reset
policy, callbacks, negative/fractional transforms, depth reset, size accounting,
alias lifetime, null bitmaps, degenerate lighting, matrix scale and the saved
bitmap prefix. The check temporarily supplies a real `gr.dc`, restores the prior
one and releases every allocation.

Both original x64 rebuild/reboot generations and the full native suite pass.
The native run completes 205 commands / 268 lines, 20 context groups, 1333
calendar checks and 4107 numerical checks, exact VGA comparisons, interruption
and startup recovery, and all 17 module rejections. All 1169 OS source hashes,
18 build-input hashes and both disk hashes match. The native disk packages all
29 files under `Adam/Gr`, including the shared public graphics header.

ConsoleRuntime 21 retains 231712 bytes (231696 image bytes), an increase of
30968 bytes. CompilerRuntime 49 retains 1342672 bytes, up 1328 bytes for helper
bindings. The kernel is 366496 bytes, leaving 22624 bytes of bootstrap headroom.
Normal boot measured 34.269 seconds and diagnostics 147.790 seconds on QEMU
486 / 8 MiB. Public graphics declarations add about nine seconds to normal boot
relative to the previous build. The verified normal preview is refreshed.

These results establish the original context service, not a complete graphics
startup, native DolDoc editor, strict 386 acceptance or physical-PC validation.
