# Shared B-spline control generation

Quadratic and cubic splines now share the control-point construction
and callback loop. Coordinates retain their original rounding and
the entire control sequence is prepared before plotting. The point
buffer is freed on success, callback rejection, and exceptions.

The fresh two-generation bootstrap and full cross-build passed,
including the 386 boot instruction audit. The
[ConsoleRuntime comparison](comparison.json) measured 2,304,040
resident payload bytes, down from 2,330,856. The serialized module
shrank by 31,649 bytes.

## Compatibility and memory

All four 96 × 80 quadratic and cubic frames, open and closed,
matched byte for byte across the 64-bit reference, the previous
native image and the new native image. Both native runs restored
the caller's data-heap usage after every curve and displayed 42
after the fixture. The [unchanged bundled demo](demo/comparison.json)
also matched all green, red and blue pixels from the existing
original run at six identical clicked coordinates. Clearing the
canvas and returning to the prompt passed.

The full cross image at 8 MiB reached the prompt with
32,544 contiguous bytes free, up from 7,824. The
[document diagnostic](boot8/result.json) still returned -1 because
the loader requested 34,588 contiguous bytes. The
[strict startup check](strict8/result.json) still failed on a startup
allocation rejection. Both 8 MiB results used KVM and `486,-fpu`.
The runtime change is verified on the cross image. The current native
generation and release gates remain open.

## Recovery

The normal cross image uses the
[previous cross archive](../i386-psalmody-fresh-v1/image-archive.json)
as its base. Use that same base for the baseline frames working
image. Recover the diagnostics image and the other working images
using the recovered candidate cross image as their base. Run
`zstd -d --patch-from=/path/to/base.img image.patch.zst -o restored.img`
with the relevant patch. The 64-bit reference ISO is compressed
without a base. The tar archives retain build receipts, generated
bootstrap binaries, screenshots and guest memory snapshots. All
archives and patches were compared byte for byte after decompression.
