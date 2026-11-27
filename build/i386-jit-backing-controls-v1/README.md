# Exact-page and startup order controls

All runtime controls used the full profile, 8 MiB, and KVM with
`486,-fpu`. The current installed image had 9,136 contiguous main-heap
bytes at the prompt and its document diagnostic returned -1.

| Control | Startup observation | Largest main free payload | Document diagnostic |
| --- | --- | ---: | ---: |
| [Source-built exact-page code allocation](source-cross/result.json) | Find and the same God providers as the cross baseline still rejected compilation | 7,824 B | -1 |
| [Installed exact-page argument control](installed-patched/result.json) | UAsmCore ran out of emitter space and setup threw `CmdPmt` before completing startup source | 169,040 B | 13 |
| [Newer providers first](extra-libraries-first/debug.log) | Autocomplete and keyboard-worker compilation failed, and boot stopped | — | — |
| [Window manager started after the libraries](late-winmgr-start/result.json) | Startup source threw `WinMgr`, with restart attempts deferred | 8,944 B | -1 |

The source-built candidate uses the existing exact-page behavior for
the task allocation callback. Its two bootstrap generations and 386
cross-build audit passed. For the installed control, only the low word
of the third argument to `I386MemAlloc` in `I386TaskCodeAllocate`
was changed from 0 to 1. The document command succeeded in that run
after essential startup had already failed. The two ordering controls
changed only `StartOS.HC`, keeping its file length and the rest of
the image byte-identical. The production source retains the original
allocation policy and startup order.

The [backing census](backing.json) starts from the exported memory pool,
walks its owned list, and reconciles every region against its outer heap
allocation. On the current installed full image, the live main-arena
backings hold only 6,656 unused page bytes and 10,064 bytes of outer
headers and alignment. Neither the main nor the fallback arena
has an empty public backing region to return. Pool trimming alone
cannot restore the contiguous space required at the full-profile gate.

## Recovery

The trial source change is in `exact-page-source.diff`. The normal
cross image patch uses the [baseline cross image](../i386-psalmody-fresh-v1/image-archive.json)
as its base. Recover the diagnostics image patch against the recovered
normal trial cross image. The other three image patches use the
[installed full image](../i386-current-nine-native-v1/gen1-install/archive.json)
as their base. Apply each patch with
`zstd -d --patch-from=/path/to/base.img case/image.patch.zst -o recovered.img`.
The runtime results and [build summary](build-summary.json) pin image
hashes. The compressed archives preserve the guest snapshots, build
receipts and generated bootstrap binaries. The patches and both tar
archives were verified byte for byte after decompression.
