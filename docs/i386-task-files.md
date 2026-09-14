# Native task file context

The native task record now carries a file-state pointer and clone/destroy hooks.
`I386TaskSpawn` clones the current task's state before publishing the child to the
scheduler. It uses the child's private arena when present, otherwise the heap
that owns the task. This does not change the optional-private-arena behavior of
`I386TaskAlloc` or implement public `MAlloc` heap selection.

Each file-state allocation owns its current-directory bytes and drive letter.
The home/boot/whitespace configuration and mounted-volume table are borrowed;
they must remain live and stable across calls, including scheduler switches.
Copying the directory at spawn prevents later child changes from altering the
parent or sibling. Shared home configuration is intentional, but synchronizing
replacement of that configuration remains part of public home/drive integration.

Management helpers preserve IF. Initialization and replacement publish only after
successful allocation. Replacement copies before freeing the old allocation, so
a directory argument may point into the old state. Clone failure during spawn
reclaims the unpublished task allocation. Provider hooks must be non-yielding,
failure-atomic and live while installed; the retained file module supplies them.
Invalid provider behavior or heap corruption is outside the rollback contract.

A borrow produces an explicit path snapshot and pins the owned directory until
release. Replacement and destruction reject busy state. Normal task cleanup runs
while file state remains attached; reap invokes its destructor before freeing the
task's arena and stack. A borrowed finished task cannot be reaped until release.
The root can inspect/manage task state, while a running worker operates on its own
state. These are cooperative lifecycle rules, not isolation or access permissions.
Cancellation or exception unwinding through an outstanding borrow is not yet
supported; callers must balance borrows on every supported return path.

## Retained service integration

FileRuntime version 3 exposes current-task read/include callbacks, volume binding
and root-state initialization. It retains the same eighteen kernel imports. The
kernel initializes the root context before boot compiler probes, binds the volume
to its ATA channel before worker startup, and lets task spawning inherit context.
All state callbacks point into the kernel-lifetime retained file image.

The current-task wrappers mask interrupts while constructing the snapshot and
restore caller IF on return. Disk polling can open interrupt windows and yield
while the file session and directory borrow remain held. Worker reads require a
bound volume; an unbound volume cannot silently fall back to raw ATA through this
interface. Root boot reads can use the quiescent unbound path. Low-level explicit
context APIs retain their IF-clear contract and optional session requirement.

The decoded-read wrapper returns owned bytes and, optionally, an owned requested
absolute name. Failure leaves output size, attributes and name unchanged. Include
callbacks preserve the original extension/normalization rules and transfer source
bytes into the existing owned lexer stack. The callback context argument is unused;
FS-bound current-task state determines the drive and directory.

## Verification scope

`python3 tools/test-i386.py --ata-tasks` exercises two inherited contexts. One
worker changes from C:/One to D:/Two; both resolve Local.BIN and read different
512-byte contents from real bound RedSea volumes on the same ATA channel. Root
observations reject directory replacement/destruction while workers have borrows.
Checks include an insufficient child arena during spawn, oversized directory
replacement, invalid directory/drive input, duplicate initialization, borrow-count
overflow, release without a borrow, borrowed finished-task reap rejection, parent
independence and final heap reclamation. Host checks compare both complete disk
images and the expected ATA command suffix, including poisoned-queue suppression.

The standalone kernel additionally exercises the retained include wrapper in boot
and worker contexts. The worker repeats nested plain/compressed includes with IF
set, verifies flag preservation and reclaims the input/codec allocations. These
checks establish private native integration, not public file API compatibility.

Public `CTask`/`CDrv`, `DirCur`, `Cd`, resident files, public errors/exceptions,
compiler-control lifetime and task/code heap policy remain integration work.
`I386TaskFilesSet` is an internal state commit, not `Cd`: it performs no directory
lookup or creation and does not implement the public partial-progress behavior.
