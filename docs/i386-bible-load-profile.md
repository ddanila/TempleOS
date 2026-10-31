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
