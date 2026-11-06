# TaskCaller reference behavior

`tools/test-i386-task-caller.py` observes the original public API on real task
stacks. It checks that TaskCaller(NULL,0) returns inside the current helper,
then starts and suspends a child in a two-function sleep chain. The saved
instruction pointer must be nonzero; walking the saved stack must find both
functions using their generated debug ranges. Saved and ordinary queries of
the suspended child must agree, excessive depth must return NULL, and killing
the child must complete. The expected seven-element vector is all ones.

* `build/i386-task-caller-original-v1/result.json`: all seven checks pass on
  the pinned original, with unchanged inputs.
* `build/i386-task-caller-native-v1/result.json`: the debug-metadata candidate
  cannot compile the first TaskCaller invocation, reporting `Invalid lval`
  at fixture line 3. Inputs are unchanged; the service is not yet exposed.

The interface-221 candidate adds TaskCaller with real scheduler-frame decoding,
CPU-stop register selection and the existing validated frame walker. Current
unsaved calls use NativeCaller with the original depth adjustment. Interrupt
exclusion protects task lookup and saved-state inspection. The initial candidate
passes all seven native checks with unchanged inputs
(`build/i386-task-caller-native-v2/result.json`); both initial bootstrap
generations and its cross-build pass, with all 1,715 source pins unchanged.
The final walker reads only the requested return address while validating every
parent transition. Its clean cross-v2 build and all 1,715 source pins pass;
`build/i386-task-caller-native-v3/result.json` repeats all seven checks on that
image with unchanged inputs. Exact welcome pixels and suspended clear/input
also pass at 8 MiB TCG 486,-fpu in `build/i386-task-caller-welcome-v1`.

The follow-up bootstrap reached the kernel build but timed out under the
180-second harness observation limit. That terminated run is preserved in
`build/rebuild-task-caller-v2-timeout`. The new --guest-timeout option retains
180 as its default; both generations pass with 600 in the follow-up run.
This is a bootstrap observation limit, not a relaxed native startup gate.

CPU debugger-context validation found two welcome-session integration gaps.
The debugger wrote a raw terminal while the welcome document retained display
ownership (v4 at 8 MiB and v5 at 16 MiB). Opening the existing legacy-view scope
above the debugger cleanup callback exposes the debugger and supports forced
exit. The v7 run then reached caller mask 31 and resumed with G, but exact
restoration failed because debugger answers were appended to the interrupted
document. Console answer recording now excludes the active debugger session.

Both revised bootstrap generations and cross-v4 pass, with all 1,715 source
hashes and build-helper hashes unchanged. Cross-v3 was terminated by the old
90-second observation limit; cross-v4 uses the explicit 600-second compiler
window without changing native timing or memory acceptance.

`build/i386-debugger-display-kill-v3/result.json` passes at 8 MiB KVM 486,-fpu
with unchanged inputs. The fixture kills a child stopped at INT3, enters and
resumes the survivor's debugger, and recovers the parent's exact welcome
document, public heap, cleared debugger mode and fresh arithmetic. Setup comes
from a source file; actual trap, focus, kill and survivor keyboard events remain
the existing CPU-kill contract. Private-resource and all-exit qualification remain
open. The earlier v1 kill harness expected a plain startup screen and did not
enter its fixture; its --welcome adaptation and packed setup preserve that
failed evidence.

The v6 caller harness had aliased interaction dictionaries across cycles; each
cycle now gets its own copy. The v8 run checks both caller masks, continuation,
registers and exact document restoration, then fails a cross-invocation heap
comparison that also counts the shell's retained transcript. The v9 fixture
instead measures each trap's before/after heap total, requiring zero growth
after warm-up. That run and the 8 MiB TCG welcome regression are pending; no
complete CPU-context or broader debugger qualification is claimed yet.

The full original-byte Psalmody workflow now loads past TaskCaller and stops at
missing scrncast in JukePuppet line 84
(`build/i386-psalmody-task-caller-v1/result.json`, inputs unchanged). The harness
explicitly loads Find and the four original God providers before the complete
application. Recording/deletion/abort checks have not yet run on the native app;
a missing screencast service cannot be replaced with placeholder state.

Native scheduling saves a private CI386Context rather than updating the public
CTask register shadows on every switch. The debugger populates those shadows
for captured CPU exceptions. An implementation must inspect the appropriate
real context and validate stack bounds; returning placeholder addresses or
reading stale public shadows for a normally suspended task would not preserve
this contract. Debugger-stop contexts and invalid-task/error cases need further
coverage. Psalmody and C1–C5 remain unqualified.

```
python3 tools/test-i386-task-caller.py --out OUT_ORIGINAL
python3 tools/test-i386-task-caller.py IMAGE --out OUT_NATIVE
```
