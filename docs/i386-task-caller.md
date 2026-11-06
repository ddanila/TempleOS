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
