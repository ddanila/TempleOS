# Document diagnostic load footprint

The diagnostic now uses a packed formatting fixture and tables for
expected binary bytes. The allocation-failure probes share lock and
heap-restoration checks. The ten formatting inputs and eighteen binary
byte assertions were compared against the previous implementation.

| Cross build | Serialized module | Module payload |
| --- | ---: | ---: |
| Triangle checkpoint | 34,588 B | 33,024 B |
| Table-only control | 33,962 B | 31,808 B |
| Compact diagnostic | 32,390 B | 30,480 B |

Two-generation bootstrap and the 386 cross-build audit passed.
On the full cross-built image under KVM with `486,-fpu` and 8 MiB,
the existing document diagnostic loaded, recorded dollar-growth
recovery, unloaded, and returned 13. The prior module could not load
with 32,544 contiguous heap bytes available. Find and several God
startup providers still logged `OutMem` on the exact image, so strict
startup remains open. Fresh arithmetic displayed 42.

The [64 MiB run](repeat64/result.json) passed two consecutive
load, recovery and unload cycles and fresh arithmetic. The
[128 MiB native build](retained/result.json) compiled the diagnostic
and verified its persisted export set against the cross-build.
The native module is 37,785 bytes. Its full native installation
and 8 MiB boot remain pending.

[Module and image hashes](comparison.json) ·
[Compact 8 MiB boot](boot8/result.json) ·
[Table-only 8 MiB control](table-control/boot8/result.json)

## Recovery

Both normal image patches use the
[triangle checkpoint image](../i386-raster-resident-v1/README.md)
as their base. The diagnostics and retained source image patches
use the corresponding normal image as their base. Restore with
`zstd -d --patch-from=/path/to/base.img image.patch.zst -o restored.img`.
The archives preserve the generated binaries, build receipts, logs,
and guest snapshots. All archives and patches were decompressed and
checked byte for byte.
