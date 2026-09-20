# Original document locking on native i386

Both x64 rebuild generations, native contention/exception tests and the full
native kernel suite pass, including public-binding checks, startup recovery and
all 17 module rejections. This is the lock integration boundary, not evidence of
a working original editor or successful document persistence.

`Adam/DolDoc/DocLockCore.HC` holds the original DocLock/DocUnlock ownership policy.
The x64 wrappers in `Adam/DolDoc/DocLock.HC` pass Fs and the original
Yield/BreakLock/BreakUnlock services. MakeDoc loads these before DocBin; DocNew
uses the already supplied document-lock interface.
Native wrappers pass the current native task and explicit adapters. The native
adapter does not publish a partial public Yield or Break interface.

The first acquisition sets the document's atomic lock bit, remembers whether it
acquired the task's break lock, and assigns ownership. Reacquiring an already
owned lock returns false. A non-owner cannot unlock it. The owning unlock clears
ownership and the atomic lock bit before releasing a break lock acquired by this
document. A pre-existing task break lock remains owned by its caller. Bit setting
and clearing use the original atomic intrinsics; the old LBEqu return value was
unused, and its assignment is now expressed as LBts/LBtr in both ports.

A native waiter calls the cooperative scheduler, then a task-context break poll.
It has not acquired document ownership, so a break while waiting cannot leave
the document locked by that waiter. An owning task defers requests while locked.
Its unlock adapter releases the task's break lock and polls after the document
is available to another task. The poll uses the retained compiler cleanup
readiness rules, allowing known active compiler controls while deferring live
waits, I/O ownership, extra resource references, and failed cleanup.

CompilerRuntime 47 adds a break_poll callback (204-byte service table).
ConsoleRuntime 13 retains the adapters and publishes `_DOC_LOCK`/`_DOC_UNLOCK`
into the root task's inherited symbol scope during initialization. Its service
and configuration sizes remain unchanged. Native StartOS loads their public
DocLock/DocUnlock declarations from PublicDocument.HH after console initialization.
The console additionally imports I386SchedYield and HashAdd. Code and export
records remain live for the kernel lifetime.

Tests cover a contending waiter interrupted before acquiring the document,
an owner interrupted on unlock, nested ownership, wrong-owner unlock, pre-existing
break locks, task destruction and heap reclamation. Interactive checks compile
calls through the retained public symbols and send an actual Ctrl-Alt-C request
while a document lock is held, then verify unlock recovery and reacquisition.

Original document creation/copy/reset/delete, callback/global initialization,
rendering, keyboard editing, executable documents and persistent save/reboot
acceptance remain required. A zero-initialized CDoc used by the lock test supplies
only the lock fields; it is not claimed to be a fully initialized document.

The full console corpus covers 164 commands / 227 input lines, seven actual
keyboard-break cases and eleven document-lock commands. Every VGA checkpoint
matches. All 1101 OS source hashes and eight build-input hashes match; both disk
images remain unchanged by tests. The normal preview is refreshed. Normal
QEMU/486 boot at 8 MiB measured 15.674 seconds; diagnostics measured 134.584 seconds.
Kernel size is 363296 bytes, leaving 25824 bytes after the 4096-byte early stage.
ConsoleRuntime retains 88776 bytes (88760-byte image); CompilerRuntime retains
1322096 bytes (1322080-byte image).
