# Full-profile startup heap isolation

The installed full image was booted at 8 MiB under KVM on `486,-fpu`.
Two controls changed only `/Kernel/I386/StartOS.HC`: each omitted
selected includes by replacing the calls with spaces and retaining line
breaks. The module payloads and boot area stayed byte-identical.

| Installed image | Main largest free payload | Fallback largest free payload | `DocAllocationCheck` |
| --- | ---: | ---: | ---: |
| Current full | 9,136 B | 792 B | -1 |
| Omit God providers | 19,040 B | 792 B | -1 |
| Omit Find, music and God providers | 22,608 B | 792 B | -1 |
| Current minimal | 149,256 B | 792 B | 13 |
| Older generation-two full, revision `84d1c25f` | 77,768 B | 496 B | 13 |

Omitting all six includes eliminated the observed startup rejections,
but the largest main-heap block was still smaller than the 33,176-byte
compacted diagnostic module. Omitting the four God includes alone left
the Find and MusicPlayCore errors. The earlier full image independently
reproduced the passing diagnostic; it also logged one startup
`OutMem` while allocating compiler IR. All five boots rendered 42
after the diagnostic command.

The two current control variants use the same eight fallback arena
allocations, totaling 549,808 bytes out of 551,936. The main arena
accounts for the measured differences. Removing all six includes
recovers 75,136 bytes of live main-heap usage. The remaining main-heap
free space is split across blocks, with a 22,608-byte maximum payload.
Restoring the full-profile gate requires freeing or preserving a
larger contiguous block with the providers enabled.

[Prompt heap comparison](comparison.json) ·
[Unmodified current images](../i386-docdiag-memory-v1/README.md) ·
[Older generation-two installation](../i386-code-alloc-known-v1/native-generations128/gen2-install/result.json)

The two control image deltas use the
[installed full image archive](../i386-current-nine-native-v1/gen1-install/archive.json)
as their base. Decompress with
`zstd -d --patch-from=/path/to/installed-full.img case/image.patch.zst -o restored.img`.
Memory snapshots and guest artifacts are in `memory-evidence.tar.zst`.
The image deltas and tar archive were verified byte for byte after
decompression. Check the retained archives with `sha256sum -c SHA256SUMS`.
