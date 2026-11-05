# Pending breaks at native cooperative checkpoints

TaskBreak.HH/HC provides an internal request/lock/unlock/poll path toward native
editor interruption. Requests set the existing public TASKf_PENDING_BREAK bit.
An unlocked ordinary request cancels a registered wait and clears its wake
deadline, but never switches tasks or redirects a saved instruction pointer.
The waiting call resumes normally, clears its registration and can release outer
resources. Repeated requests coalesce in the pending bit.

Lock returns whether it newly set TASKf_BREAK_LOCKED. Unlock returns whether it
cleared that bit and retries pending wait cancellation. Neither operation delivers
an exception. Locked requests retain the lock until explicit unlock. This staged
policy deliberately differs from the original scheduler's immediate saved-RIP
rewrite and lock-bit clearing on request; it is not published as the original
BreakLock/BreakUnlock contract. Original document unlock integration must retain
its required delivery semantics when the full cleanup path is installed.

Poll operates on the current live task at an explicit cleanup checkpoint. It
keeps the request pending while a wait, blocked state, I/O lock, borrowed lifetime
reference, active compiler control, compiler busy/failure state, or inbox remains.
Break-to-Shift-Escape also stays pending because its message path is not yet
integrated. Eligible delivery clears the pending bit, restores caller IF and
throws the native 'Break' exception through the existing exception runtime.

These guards are necessary but not a proof that arbitrary code can be interrupted.
The caller must first release temporary allocations and other resources not
represented by the guards. The general poll is not automatically installed in scheduler or IRQ paths.
Compiler input now has a separate [protected cleanup boundary](i386-compiler-break-cleanup.md)
that owns and unwinds its active controls. That does not permit bypassing the
general poll guard at an arbitrary call site. Public Break, message flush,
popup/job behavior, focused keyboard requests and non-yielding program interruption
remain unfinished.

The native exception-task corpus exercises three real sleeping-worker scenarios:
unlocked request, locked request followed by unlock, and deferred Shift-Escape
followed by an ordinary request. It verifies repeat requests, registration
lifetime, cleared wake deadlines, IF preservation, real catch/recovery and complete
exception/task heap reclamation. Separate injected ownership-counter states prove
that Poll refuses premature delivery; these do not establish actual file/compiler
unwinding. Both x64 rebuild generations and the native exception-task suite pass.

The larger exception fixture loads up to 512 sectors below physical 0x50000,
uses a 32 KiB heap at 0x50000, and places temporary segment records at 0x70000.
The previous 384-sector transfer limit rejected the expanded runner before boot;
no runtime failure was hidden by this adjustment. Other fixture profiles remain
unchanged. Production kernel modules, service versions and the QEMU preview are
unchanged; this slice is a tested internal implementation awaiting integration.

### Public BreakLock/BreakUnlock reference (2026-11-05)

`tools/test-i386-break-lock.py` captures 30 actual public-API observations in
`build/i386-public-break-lock-reference-v1/result.json`, all passing with
unchanged inputs. The original returns 1 only for the first lock or for an
unlock that removed the lock. Default and explicit current-task arguments
agree. Unlocking a pending current-task break clears both bits and synchronously
throws Break before the following statement. For a suspended foreign target,
unlock clears the pending bit immediately while preserving suspension; after
resumption the child catches Break and exits without executing the next user
statement. Both initially locked and unlocked foreign targets are checked.

The eb98054d native interface lacks these APIs. The real fixture fails
to compile its BreakUnlock call in
`build/i386-public-break-lock-native-red-v1`; its frozen driver and failure
classification are retained. No native state transition is qualified by that
failed setup. Existing internal I386TaskBreakUnlock deliberately leaves pending
delivery to guarded checkpoints and cannot simply stand in for this public
contract. A native foreign-task delivery must respect its saved-ESP context and
resource/borrow cleanup rather than replacing only a saved PC. Shift-Esc routing,
foreign kernel waits and the broader API/application milestones remain open.

### Public native break locks (2026-11-05)

The isolated public-break candidate implements public BreakLock and BreakUnlock
with default/current and foreign task arguments. Lock operations touch only the
public writable CTask flags. Unlock clears both lock and pending bits immediately
and returns the old lock bit; a pending current-task action calls the actual
NativeBreak synchronously, including its Shift-Esc message path.

For another task, unlock sets the public RIP to Break and queues a private
action on proven native task storage. The memory provider resolves native
identity through its private scheduler ring or owned-task records, including
unqueued tasks; a standalone CTask descriptor never exposes private fields.
The action runs on the target after native waits/borrows have ended, at public
yield, generated execution/input checkpoints or guarded task checkpoints.
Suspension and wait state are preserved. No saved-ESP return frame is rewritten.
A fresh task processes the action before user entry; if Shift-Esc makes Break
return, that task exits instead of entering its displaced user function.

The additional pointer is private to CI386Task; public CTask layout is unchanged.
Memory/Compiler/Console runtime versions advance to 40/84/211. Host validators
accept the exact new provider modules and reject actual previous 39/83/210
modules (`build/i386-public-break-lock-v5/interface-version-audit.json`).
The ordinary no-action polling path returns before IRQ work.

The expanded original lock reference passes 36 observations, including writable
standalone-descriptor flags and RIP, in
`build/i386-public-break-lock-reference-v2/result.json`. The original routing
reference passes 29 observations in
`build/i386-public-break-routing-reference-v1/result.json`: exact Shift-Esc key
and scan-code messages for current and suspended foreign tasks, immediate
flags, preserved IRQ state, and fresh unqueued task replacement without user
entry. Native lock-v2 and routing-v1 pass the same observations through five
normal-image commands each, with unchanged inputs and exact frames, at 8 MiB
KVM/486 without FPU. Startup is 33.730 and 33.722 seconds respectively. The first
native checker stopped at an unsupported local array initializer; its frozen
failure is retained and the constants now reside in a global array. Exercised
actions and expected values are unchanged from the passing original references.

Both original bootstrap generations, cross-build and 386 instruction audit pass.
All 1,365 delivered source/doc files match. The 16 MiB TCG/486 diagnostic passes
both phases, 54 input cases, both header/code-lifetime and actual queued-file
cancellation cases, and the exact welcome frame in
`build/i386-public-break-lock-diagnostic-v1/verification.json`. These are ordinary
cancellation regressions, not public-break coverage of every foreign kernel
wait. Such wait/resource cases, broader desktop/API behavior, minimal-profile
resource acceptance and all C1–C5 milestones remain open.

### Public wait boundaries (2026-11-05)

`tools/test-i386-break-lock-wait.py` adds actual public Sleep and GetMsg receiver
workflows. The parent queues a pending unlock while the receiver is suspended,
checks immediate flag clearing and preserved suspension, posts a real key for
the message case, then resumes the target. Each child catches Break before
its post-wait statement, exits naturally, reports zero wake/pending/await flags
and no remaining key message, and preserves its IRQ state. No stand-in wait
or simulated return value is used.

The original and native each pass all 28 observations in
`build/i386-public-break-wait-reference-v1/result.json` and
`build/i386-public-break-wait-native-v1/result.json`. The native normal-image
session passes all five commands with unchanged inputs and exact frames.
This extends public-wait coverage; ATA/file/provider borrows, other foreign
resource classes and all C1–C5 acceptance still remain open.
