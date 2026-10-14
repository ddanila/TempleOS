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

## Forced callback Exit and native render scopes

Ordinary catch cleanup does not run when a callback calls Exit. The native task
scheduler performs task cleanup while the exiting stack and its parent's heaps
are still live; render resources must be released there as well.

```
python3 tools/test-i386-doc-recalc-exit.py IMAGE --out build/FRESH-exit
```

The first test on the preceding image returns 4 instead of 31
(`build/i386-c4-doc-recalc-exit-red/result.json`). A child exits inside a tag
callback; the old tag remains intact after the earlier replacement fix, but its
parent-owned document lock and drawing alias remain live. The parent does not
try to delete that locked failure-case document.

Kernel/I386/DocRecalcScope.HC registers stack-resident render scopes with the
current task's cleanup chain. Scopes reference the renderer's current document,
lock ownership and pending alias/depth/tag storage. Normal return or exception
unregisters the scope; forced termination drains that task's nested scopes and
then invokes its prior cleanup. The list is protected during registration and
removal and supports interleaved scopes from different cooperative tasks.
Original builds use no-op scope macros; the native lifecycle adapter owns the
scheduler hook. It does not add resident allocation-based diagnostics.

The test covers a plain child, nested inner/outer recalculations, and a User
terminal task with existing terminal cleanup. Each case requires released locks,
cleared owners, retained tags, exact parent heap recovery, successful retry and
exact heap after document deletion. Terminal source receives the parent document
by explicit address, rather than depending on private symbol visibility.

The first cross-build rejected a function-pointer declaration initializer. The
native implementation now declares and assigns separately, without changing the
cleanup policy.

The corrected image passes all twenty commands, returning 31 for all three
exit cases (`build/i386-c4-doc-recalc-exit-green/result.json`). The existing
ordinary callback exception/retry test and two-phase full-frame style test also
pass (`build/i386-c4-doc-recalc-exit-catch/result.json` and
`build/i386-c4-doc-recalc-exit-frame/result.json`). Bootstrap rebuild, cross-build
and 386 boot audit pass (`build/i386-c4-doc-recalc-exit-pointer-cross`). Startup
passes at 8 MiB in 45.59 seconds with no build-provider loads
(`build/i386-c4-doc-recalc-exit-startup/result.json`). Interleaved-task scopes and
local mesh-depth cleanup are supported by the implementation but not separately
qualified by these tag-callback cases.

This is renderer scope cleanup. It does not yet qualify forced exit from the
outer NativeGraphicsPresent/GraphicsFrameCore callbacks, framebuffer-lease
release, owner termination during a yielding callback, or arbitrary cleanup
wrappers installed and left active by a callback. Those remain refresh-worker
lifecycle gates before automatic presentation is enabled.
