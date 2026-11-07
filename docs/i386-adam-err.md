# Public Adam error output on i386

The unchanged original `AdamErr` body is shared in `Kernel/AdamErrCore.HC`.
It formats the red blinking error prefix, prints directly in Adam, suppresses
cross-task output in single-user mode, and otherwise submits output through the
existing real Adam job service. `Kernel/IsSingleUserCore.HC` shares the original
semaphore read. Native public exports use console version 240.

`tools/test-i386-adam-err.py` runs from a child task, primes Adam before capturing
output, checks single-user suppression and caller-document preservation, then
captures routed and direct Adam-task output. Exact styled document bytes are
compared, including the cursor marker. Original v4 passes mask 31; its independent
audit verifies restored reference sources, input pins, fixture and both documents.
The native baseline rejects the first AdamErr call before behavior; its audit
checks normal startup, fixture-only volume changes and unchanged boot bytes.
Evidence is under `build/i386-adam-err-original-v4` and
`build/i386-adam-err-baseline-v1`.

Exploratory v1 was interrupted after discovering an unescaped nested format
specifier and first-use startup banner. V2 captured correct routing documents
but failed an assumed empty-document representation. V3 compares the caller
output against its actual initial bytes and passes. These records are retained;
v4 is the reusable exact-output reference. The unchanged bodies separately pass
native source-loaded publication in `build/i386-public-adam-err-loader-v1`.

Both bootstrap generations pass with stable inputs. Native integration passes
mask 31 and both exact original styled documents in
`build/i386-adam-err-native-v1`. Its independent audit verifies matching fixture,
mask, documents, current pins and normal startup. Final-image 8 MiB welcome and 16 MiB diagnostics pass all 307,200 welcome
pixels. Diagnostics complete both program, ownership and file-break cleanup
phases with normal source startup. Evidence is in
`build/i386-adam-err-welcome8-v1` and `build/i386-adam-err-diagnostic16-v1`;
`build/i386-adam-err-cross-v1/final-contract-audit.json` verifies source pins,
exact contracts and both profiles. These are regressions, not C5 generations. This contract does not cover allocation failure, competing document
writers, complete compiler diagnostics or full C1–C5 qualification.
