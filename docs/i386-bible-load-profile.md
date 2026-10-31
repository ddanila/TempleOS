# Bible document loading profile

The full Bible editor-link test timed out during its first lookup at the
20-minute command limit. To locate the expensive stage,
`tools/test-i386-bible-load-profile.py IMAGE --out OUT` loads four prefixes of
`Misc/Bible.TXT` into disposable guest files. Each case reads its excerpt,
inserts it into a plain-text document, lays it out, finds Genesis 1:1, and
frees it. The host records debug-marker arrival times; these are elapsed QEMU
measurements, not CPU samples or a physical-machine benchmark.

The run on the Console 176 native image passed all four searches with unchanged
inputs (`build/i386-bible-load-profile-v2`). Times are approximate seconds:

| Lines | Read | Insert | Layout and search | Cleanup | Total |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 400 | 2.3 | 1.8 | 9.0 | 7.3 | 20.4 |
| 800 | 4.9 | 5.2 | 0.1 | 21.5 | 31.8 |
| 1,200 | 7.1 | 10.7 | 0.2 | 43.8 | 61.8 |
| 1,600 | 10.7 | 18.7 | 0.2 | 72.6 | 102.2 |

The first search also includes loading the editor module, so the first search
is not directly comparable with the later cases. Cleanup grows rapidly and is
the largest measured stage at 1,600 lines; insertion also grows faster than the
file read. This does not by itself identify a particular function or establish
full-file completion. Public `MemoryFree` invokes backing-pool reclamation after
every non-null free, including small frees that remain in the heap cache; the
cost of that validation and its corruption-detection guarantees need to be
measured before changing it.

The first profiling attempt completed two cases but lost the next keyboard
command (`build/i386-bible-load-profile-v1`); the accepted run sends one
combined command and records partial markers even on failure. The test uses
bounded excerpts and is not a substitute for the full Bible test, installation,
application compatibility or C1–C5 qualification.

A separate QMP sampler paused a 1,200-line run during cleanup
(`tools/profile-i386-bible-cleanup.py IMAGE --out OUT`,
`build/i386-bible-cleanup-pc-v1`). Of 213 samples, 208 landed in
`I386HeapScanSelect` with callers through `I386HeapSize`,
`I386MemBackingValid`, `I386MemBackingTrim` and `MemoryReclaim`; four more
landed in the same scan through `I386HeapValid`. These are statistical samples,
not call counts or elapsed-time measurements. They support targeting repeated
whole-arena validation while retaining the full validation and ownership checks.

## Validated backing lookup

Memory runtime 34 validates the entire bootstrap heap once while interrupts are
masked, then walks that already-validated chain to find each backing region's
exact allocated block and requested size. It does not cache validation or skip
reclamation. An inline 386 span walk avoids the cost of generated wide-code
loops; the portable source path uses the same bounded offsets. The public heap
contract compares the result with the previous full-scan implementation on
valid state, changed ownership counts and sizes, reserved metadata corruption,
and a forged pointer inside a different live allocation. Native and portable
heap tests pass (`build/i386-backing-validator-test-v4.log`,
`build/i386-backing-validator-source-test-v3.log`). Both bootstrap generations
and the native cross-build/386 audit pass
(`build/i386-backing-validator-rebuild-v3.log`,
`build/i386-backing-validator-cross-v3`). The 8 MiB drive-fields smoke
check also passes (`build/i386-backing-validator-smoke-8m-v2`).

The same scaled workload passes on the candidate with unchanged inputs
(`build/i386-bible-load-profile-optimized-v3`): at 1,600 lines, read took about
6.8 seconds, insertion 5.5 seconds, cleanup 19.5 seconds, and total 32.0 seconds.
The earlier image took 10.7, 18.7, 72.6 and 102.2 seconds respectively. These
are approximate host-observed QEMU timings; another guest was active during the
candidate run and the command wrapper was shortened, although the measured
`BibleProfile` stages and text samples are unchanged. The improvement does not
qualify the complete Bible or eliminate its scaling cost. An earlier generated
walk showed severe slowdown and keyboard input resets, so it was superseded;
its partial run was stopped after the inline candidate superseded it
(`build/i386-bible-load-profile-optimized-v2`, inputs unchanged); its failed
concurrent command attempt is `build/i386-bible-load-profile-optimized-v1`.

The candidate passes the isolated initial memory probe in diagnostic boot. The
full 8 MiB diagnostic later exhausts the bootstrap heap on both candidate and
prior images (`build/i386-backing-validator-diagnostics-v1`,
`build/i386-backing-validator-diagnostics-control-v2`). At 16 MiB both reach
the later public-header probe and fail on the same `PublicTask.HH` invalid-lvalue
error (`build/i386-backing-validator-diagnostics-16m-v1`,
`build/i386-backing-validator-diagnostics-control-16m-v1`). The control used
the default 486 CPU setting; these matching failures do not establish complete
diagnostic qualification.

The normal 8 MiB startup gate completed all nine behavior checks but exceeded
its 60-second target: 77.399 seconds for the candidate and 84.891 seconds for
the prior image in an isolated control checkout
(`build/i386-backing-validator-startup-v1`,
`build/i386-backing-validator-startup-control-v2`). Both gates therefore
remain failed on timing; these two runs do not prove the startup target. The
runner was updated to expect the current welcome screen, and its 60-second
threshold was retained.
