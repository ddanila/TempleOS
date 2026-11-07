# Public compiler error location on i386

The original `FixSet` formats `FL:filename,line`, takes `SEMA_FIX` using atomic
bit operations and Yield, replaces the previous debugger file link with an
Adam/system-lifetime copy, and releases the semaphore. Its unchanged body is
shared in `Kernel/FixSetCore.HC`. The original CMPCrash/CDbgGlbls declarations
are shared in `Kernel/DebugGlobalsTypes.HH`, replacing the native formatter's
reduced two-field debugger state. The native public API exports FixSet and dbg;
console version 239 records these additions.

`tools/test-i386-fix-set.py` checks exact file-link text, independence from the
caller's filename buffer, replacement with a negative line number, and release
of the semaphore. The original reference passes mask 15 in
`build/i386-fix-set-original-v2`; the exploratory original v1 result has an
independent reference-tree/fixture audit. The pre-change native image rejects
its fixture at the missing public dbg symbol before behavior, in
`build/i386-fix-set-baseline-v1`. Its audit verifies startup and historical
builder pins. The original bodies and function/data export slots have a
separate parity audit in `build/i386-fix-set-source-parity.json`.

Both bootstrap generations pass with stable source inputs. Native behavior passes the same mask 15 in `build/i386-fix-set-native-v1`.
Its independent audit verifies exact original fixture/result, current input pins
and normal source startup. Final-image 8 MiB welcome and 16 MiB diagnostic profiles pass all 307,200
welcome pixels. Diagnostics complete both program, heap-ownership and file-break
cleanup phases with normal startup. Evidence is retained in
`build/i386-fix-set-welcome8-v1` and `build/i386-fix-set-diagnostic16-v1`;
`build/i386-fix-set-cross-v1/final-contract-audit.json` independently verifies
source pins, exact contracts and both profiles. These are regression profiles,
not full C5 installed generations. The premature v1 bootstrap was
canceled after an encoding error prevented the native integration edits; its
output remains in `build/rebuild-fix-set-v1-cancelled`. It supplies no acceptance
evidence.

The four-check contract does not cover contention, allocation failure, Fix's
editor workflow, crash handling, or all debugger fields. Restoring this shared
state does not qualify those services, full compiler diagnostics, or C1–C5.
