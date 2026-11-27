# Raster code footprint controls

Both candidates rebuilt through two bootstrap generations and passed the
386 boot instruction audit. The comparison uses the full image from
the [shared B-spline checkpoint](../i386-spline-storage-v1/README.md).

| ConsoleRuntime build | Resident payload | Serialized module |
| --- | ---: | ---: |
| Shared B-spline baseline | 2,304,040 B | 2,446,116 B |
| Shared Bézier trial | 2,304,936 B | 2,445,198 B |
| Shared triangle span loop | 2,302,392 B | 2,444,499 B |

The Bézier trial matched eight ordered callback traces on the 32-bit
and 64-bit guests. The cases covered both orders, suppression of the
first point, cancellation at the third point, and endpoint mutation.
The trial increased the resident payload by 896 bytes and was reverted.
Its patch and [boot receipt](bezier/boot8/result.json) are retained.

The triangle refactor shares span iteration after the existing edge
setup and clipping. It saves 1,648 resident bytes. All 96 cases
matched the 64-bit reference and previous native image byte for
byte, including pixel counts, color and depth buffers. The cases
cover both scan axes, every vertex ordering, and clipped edges.
The [native candidate](triangle/candidate/result.json) still
rendered 42 after the probe.

Both candidates
still show a 32,544-byte largest free payload at the 8 MiB prompt.
The [triangle diagnostic command](triangle/boot8/result.json) returned
-1 and the [strict startup check](triangle/strict8/result.json) still
stopped on a startup allocation rejection.

## Recovery

[Image and module hashes](comparison.json) pin all binaries. Both
normal image patches use the [shared B-spline image](../i386-spline-storage-v1/README.md)
as the base. Each diagnostics image patch uses the corresponding
normal candidate image as the base. The working image patches use the
corresponding baseline or candidate normal image. Use
`zstd -d --patch-from=/path/to/base.img image.patch.zst -o restored.img`
with the relevant patch. Both reference ISO patches use the
uncompressed `bezier/reference.iso.zst` image as the base. Archives
and patches were checked by decompressing and comparing bytes.
