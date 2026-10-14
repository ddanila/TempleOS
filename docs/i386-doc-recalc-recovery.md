# Document renderer callback recovery

Scheduled rendering needs callback failures to leave documents usable. The
shared original DocRecalc body previously freed a tag before asking its callback
for the replacement, and had no outer resource/lock cleanup on propagation.

```
python3 tools/test-i386-doc-recalc-callback-fault.py IMAGE --out build/FRESH-fault
```

The fixture creates a retained tag, then makes its callback throw TagFail during
TO_SCRN recalculation. On the preceding image, it observes mask 4 rather than 31:
the entry still contains the old pointer, but lock/owner and exact heap-recovery
checks fail. The old pointer had already been freed; pointer equality alone is
not evidence of valid tag storage. The test does not delete the corrupted
failure-case document. Evidence:
`build/i386-c4-doc-recalc-callback-red/result.json` and command-08 framebuffer.

The shared renderer now obtains a replacement before freeing/publishing over the
old tag, for callback and define-backed updates. Its outer scope cleans up the
drawing alias, pending replacement and local depth buffer, and releases only a
lock it acquired. Normal unlock clears its cleanup flag first so a pending
break propagated after unlock cannot trigger a second unlock. An attached local
depth buffer is detached before alias destruction to avoid freeing it twice.

The required success mask covers lock release, cleared owner, retained pointer,
exact heap after the caught failure, then successful retry and exact caller heap
after document deletion. A normal retry must replace the tag with ready. This
is a targeted exception test; forced Exit, all allocation failures, every
renderer callback and full frame-worker lifetime remain unqualified.

The corrected native image passes all ten commands and returns the required 31
mask (`build/i386-c4-doc-recalc-callback-green/result.json`). The original
text-cell/layout oracle also passes on that image
(`build/i386-c4-doc-recalc-recovery-cells/result.json`). Bootstrap, native
cross-build and 386 boot audit pass (`build/i386-c4-doc-recalc-recovery-cross`).
The rebuilt-original automatic A/B refresh control remains green, and native
8 MiB startup passes in 45.88 seconds with no build-provider loads
(`build/i386-c4-doc-recalc-recovery-startup/result.json`). This does not close
the native automatic-refresh gate.
