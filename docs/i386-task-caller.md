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

CPU debugger-context validation found a display ownership gap: the debugger
writes a raw terminal, but the welcome document retained the screen. The v4
8 MiB and v5 16 MiB runs both reached INT3 without exposing the debugger.
The candidate now opens the existing legacy-view scope above its task cleanup
callback and closes it on normal/error return; forced exit unwinds that scope
before the debugger callback. Both bootstrap generations and cross-v2 pass,
with all 1,715 source pins unchanged (`build/i386-debugger-display-cross-v2`).

The first v6 trap displays the expected debugger and yields caller mask 31,
but that run fails after a duplicated fixture command: the base fixture repeats
the same interaction dictionary, and deepcopy of the whole list preserves those
aliases. The corrected harness copies each cycle separately. The v7 run reaches mask 31 and resumes with G, then its exact restore raster
fails: debugger answers were appended to the interrupted welcome document.
The follow-up candidate suppresses transcript recording during a debugger
session; its bootstrap is in progress. No complete CPU debugger-context pass
is claimed yet.
Forced-exit validation is also pending in debugger-display-kill-v2. Its v1
attempt expected the older plain startup screen and never entered the fixture;
the harness now supports an explicit --welcome option.

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
