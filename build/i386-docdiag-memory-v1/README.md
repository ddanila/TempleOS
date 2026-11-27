# Document diagnostic heap comparison

Four snapshot boots used KVM with `486,-fpu` and 8 MiB. The native
minimal control was built from the cross minimal image with exactly the
nine installed native module payloads substituted. The boot area and
all other filesystem entries matched byte for byte, including
attributes and timestamps.

| Image | Largest free payload at prompt, bytes | `DocAllocationCheck` |
| --- | ---: | ---: |
| [Cross full](cross-full/result.json) | 7,824 | -1 |
| [Installed full](installed-full/result.json) | 9,136 | -1 |
| [Cross minimal](cross-minimal/result.json) | 173,336 | 13 |
| [Installed minimal](installed-minimal/result.json) | 149,256 | 13 |

Both full images logged `OutMem` startup source rejections before the
ready marker. The rejected sources included Find and several God
libraries on both images and MusicPlayCore on the installed image.
The diagnostic failed in `I386RedSeaLoadBoundCapacity` on both.
The installed module needs a 40,359-byte allocation before compaction
and still occupies 33,176 bytes after compaction, including its entry
stub. The 9,136-byte free block cannot hold even the compacted module.

Both minimal controls recorded one load, dollar growth recovery and
unload. All four boots rendered 42 after the diagnostic command. A
separate [User startup test](user8-installed-minimal/result.json) on
the installed minimal image reached `USCheck` and failed on a
267,527-byte allocation. The required full-profile 8 MiB installation
gate remains open and the flat native generation rebuild is pending.

## Evidence recovery

`memory-evidence.tar.zst` contains the prompt and post-command physical
memory snapshots and guest artifacts. Each snapshot's SHA-256 is in
its case's result JSON. The archive was verified byte for byte against
the source tar.

The full images are recoverable through the
[cross archive](../i386-psalmody-fresh-v1/image-archive.json) and
[installed archive](../i386-current-nine-native-v1/gen1-install/archive.json).
Each minimal image patch was verified byte for byte on decompression
using that same installed full image as its base. Run
`zstd -d --patch-from=/path/to/installed-full.img case/image.patch.zst -o restored.img`
from this directory. The restored image hashes are in the case results.
For the User startup image use `packaging.image_sha256`. Run
`sha256sum -c SHA256SUMS` here to check the archive and patches.
