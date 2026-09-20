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
