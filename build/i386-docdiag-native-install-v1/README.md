# Guest-built document diagnostic

The guest installed the audited 37,785-byte module byte for byte. The installed
filesystem bitmap matched the reachable extents. Each boot used a fresh QEMU
snapshot with a 486 CPU and the FPU disabled.

| Module | RAM | Largest free payload at prompt | DocAllocationCheck |
| --- | --- | ---: | --- |
| Guest-built | 8 MiB | 32,544 bytes | −1, loader allocation failed |
| Guest-built | 16 MiB | 7,216,496 bytes | 13, load, recovery and unload passed |
| Host-folded control | 8 MiB | 32,544 bytes | 13, load, recovery and unload passed |

All three guests subsequently evaluated 6 × 7 as 42. Both 8 MiB boots reported
startup rejections in Find and the God libraries. The host control resolved
169 module-local references and reduced the module to 32,542 bytes. Native
compiler output still exceeds the available contiguous allocation at 8 MiB.

## Evidence and recovery

The per-boot directories contain the result and debug log. The runtime archive
holds the original install and boot evidence, including physical memory captures.
The scripts record the installation, control transformation and measurement.

Start with the retained source image described in the
[compact diagnostic checkpoint](../i386-docdiag-compact-v1/README.md).
Apply the two patches in order. The receipts list the expected SHA-256 hashes.

```sh
zstd -d --patch-from=source.img installed.patch.zst -o installed.img
zstd -d --patch-from=installed.img folded.patch.zst -o folded.img
```

Both restored images and all runtime archive members were compared with the
originals before removing the redundant scratch images from tmpfs.
