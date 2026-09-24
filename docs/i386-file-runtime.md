# Retained file services and disk-backed compiler includes

FileRuntime now requires ABI 25 (48 bytes). Its current-task service table adds
failure-reporting writes and directory creation to the existing read/include,
path, compiler-control and ownership operations.

`FileRuntime.t32m` packages native path construction, filename rules, archive
expansion, decoded file loading, drive-context routing and the compiler file-input
bridge outside the conventional-memory bootstrap. The kernel loads it from RedSea
into the extended-memory heap and retains its image for the kernel lifetime.
The six linked bootstrap modules are unchanged in number. Ten modules are now
packaged: those six, retained CompilerRuntime and FileRuntime, and temporary
Startup and CompilerProbe.

## Interface and ownership

CI386FileServices version 25 is a 48-byte i386 record: version/byte-count fields,
current-task include/read/write/directory callbacks, volume binding and root
task-state initialization, compiler configuration, path construction, control
construction and queued-I/O cancellation.
Initialization writes a caller-owned candidate. The kernel validates the version,
size and all six addresses before publication; the host independently compares
them with export offsets. The retained image owns canonical channel gates and I/O
tables, initialized by the root-only binding service.

The module imports the heap, interrupt, RedSea, lexical, ATA, scheduler and debug
providers required by its retained operations. It retains its string/codec
code and task/session adapters, with no duplicate PIO protocol or allocator.
The kernel supplies 27 explicit bindings to FileRuntime.

The boot configuration borrows one mounted volume in drive slot C, home/boot
configuration and the original whitespace bitmap. The root owns its directory
state; children inherit independent directory/drive values at spawn. Read/include
callbacks use the FS-bound current task and borrow its state across disk polling
and yields. The code images and shared configuration/volumes must remain live.
Kernel shutdown is the current image lifetime; general module unloading remains
separate work. See [i386-task-files.md](i386-task-files.md) for lifetime rules.

Failed module loads and incompatible returned interfaces reclaim their allocations
and preserve the pre-load heap baseline. Three boot mutations exercise a wrong CPU
tag, unresolved import and wrong service version. They must halt before compiler
probes/startup, with no file interface published. Disk contents remain unchanged.

## Connected compiler path

CompilerProbe's version-3, 52-byte borrowed record includes the disk provider and
file-service table.
At boot, its version-13 retained lexer reads a root include directive, calls the
retained file provider, loads a plain outer source through the default HC.Z
fallback, then expands a compressed inner source. The inner archive is produced
by the original x64 compressor during the build. The lexer returns 11, 22 and 33,
then the parent delimiter and EOF; the test verifies 68 consumed source lines and
complete temporary reclamation.

A malformed compressed source also has a valid plain alternate. The provider
correctly reports failure without selecting that alternate, and the lexer resumes
at parent value 44. This connects the existing loader's failure policy to actual
retained include dispatch. Source bytes and copied names follow the existing owned
file-stack contract; the codec's controls/stacks and temporary archives are freed.

Current-task callbacks preserve caller IF. After boot-time module loading and
startup, the kernel binds C to the runtime's canonical channel gate before starting
tasks. The task-phase probe performs nested disk reads and archive-error cleanup,
then repeats the nested reads with IF set and verifies flag preservation (136
consumed lines across both traversals). Polling yields with the file session and
path borrow still owned. Both phases also call the decoded-read entry directly,
checking owned bytes/name and unchanged outputs after malformed-archive failure.
See [i386-redsea-tasks.md](i386-redsea-tasks.md) for session scope and restrictions.

After the task probe returns, the kernel reclaims its diagnostic module and verifies
that both compiler and file-service images remain live allocations of their
recorded sizes. Every borrowed callback into the diagnostic module has returned
before it is freed; the kernel's disk callback points into retained FileRuntime.

## Verification and measurements

Commands:

```
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
```

Both x64 rebuild/reboot generations and the complete native boot suite pass:
connected disk includes, malformed-archive recovery, enabled-IF preservation, image
lifetime/reclamation, all module rejection cases, source checks, VGA/keyboard/timer
checks, unchanged disks and executable-region instruction audits across all ten
modules. This remains an 8 MiB QEMU/486 development result.

Current images and allocations:

| Component | Image bytes | Heap bytes |
| --- | ---: | ---: |
| CompilerRuntime, retained | 260080 | 260096 |
| FileRuntime, retained | 124688 | 124704 |
| CompilerProbe, reclaimed after task check | 100000 | 100016 |

The native bootstrap is 389336 bytes. With its 2160-byte loaded stage overhead,
391496 bytes occupy the unchanged 393216-byte reservation, leaving 1720 bytes.
The separate 512-byte boot sector is excluded from that reservation. Further
bootstrap growth needs extraction or reduction; the low-memory reservation has
not been raised. Task allocation helpers and scheduler join are separately
linkable; the current boot kernel links lifetime and scheduler core only. The full
`Task.HC` and `Scheduler.HC` wrappers retain those helpers for other callers.
Bounded export-index tables replace repeated binding setup calls
and recover conventional-memory space. These are measured artifacts built with local changes before
commit; manifests record revision and source hashes.

Public task/drive binding, resident-file caching, public errors/exceptions,
reset recovery and latency measurement, full compiler-control lifetime, parser/JIT,
DolDoc and persistent editing, strict 386SX/DX profiles and native self-hosting
remain open. The connected include path is a compiler prerequisite, not a claim
that the full native programming environment is complete.

The disk probe now constructs controls through the current-task factory in this
module. Configuration borrows the retained compiler, default temporary filename
and original bitmaps; controls pin the task through destruction. See
[i386-task-compiler.md](i386-task-compiler.md) for semantics and remaining public
API integration.

## Public directory creation and nested project files

`DirMk(U8 *filename,I64 entry_cnt=0)` is now a public native HolyC service. It
allocates a contiguous RedSea directory, publishes an `0x810` parent entry, and
writes canonical `.` and `..` records. Requested entry capacity is rounded to
whole 512-byte directory blocks.

File writes now acquire the task-owned ATA channel before resolving a parent
directory and retain it through lookup, create/replace, flush and release. Root
files previously hid this ordering defect because choosing the root required no
disk read. Failure paths release the channel and borrowed task-file state and
emit a bounded debug marker.

The writable QEMU acceptance creates `C:/Project/Sub/Main.HC`, saves and executes
it through F5 as `49`, then reboots and reopens/executes the same nested file.
The independent post-run walk verifies all directory parent records, reachable
extent ownership, the allocation bitmap and the exact five persisted program
bytes. See `build/i386-doldoc-deep-integrity-green-1/result.json`.

Growing the root relocates its contiguous extent. The native mutation path now
rewrites every direct child directory's `..` record to the published root before
freeing the old extent. Without that repair, ordinary file reopening still
passed while parent navigation referenced a freed historical root block.

ABI 32 extends the 72-byte ABI 31 record to 76 bytes with a private raw
write/flush move-failure callback. It is enabled only on disposable writable
images; the public file API is unchanged. The existing services include a
bounded two-pass directory enumerator plus
regular-file delete, empty-directory delete, same-parent entry rename and
cross-directory regular-file move services. It resolves through the current task's drive/directory context, holds the task-owned
ATA session across every directory sector, skips deleted entries, preserves
on-disk order and appends `/` to directories. The public `Dir(path)` command
prints that listing at the live HolyC console without transferring ownership of
file-runtime allocations.

`FileMove(old,new)` accepts task-relative or absolute paths on one mounted
volume. A same-parent move uses the atomic directory-entry rename path. A
cross-directory move reads the regular file, publishes a destination preserving
its date and attributes, and only then deletes the source; if source deletion
fails it attempts to remove the destination. Directory sources and destination
collisions are rejected. This protects the source until a complete destination
exists, but it is not a crash-atomic directory-entry transaction. ABI 31
appends an internal staged move-failure probe callback; ABI 32 appends the raw
I/O callback
after the public move callback.

Cross-directory moves now write a checksummed, volume-wide intent before
publishing the destination. It records root-aware parents, both leaf names and
the source identity. Successful moves clear it only after source deletion and
reclamation are durable. Before task I/O is published, mount recovery validates
the intent and live records, rolls back the destination while the source remains,
or accepts the destination once the source is absent. The 13-case raw failure
matrix requires exactly one complete name, an all-zero intent area and bitmap
ownership matching the reachable tree after every recovery boot.

The same private fault callback selects replacement write and flush operations.
A seven-case matrix replaces a three-byte `OLD` fixture with `NEW` and reboots
after each interrupted raw operation. Copy-on-write ordering plus mount bitmap
reconstruction preserves the old file before publication and the new file after
publication; incomplete contents are rejected independently of guest APIs.

The probe runs only when build tooling enables a separate writable boot flag on
a disposable image. It injects failure before source reading, before destination
creation, after destination publication and before source deletion. Each case
requires the exact source bytes and an absent destination, then the probe performs
a successful move and removes its fixtures. Build promotion clears both boot
flags, walks every live extent and bitmap bit, and boots the resulting disk
normally to prove the fixture paths remain absent. Ordinary diagnostic startup
does not invoke the probe and remains byte-for-byte read-only.

The focused QEMU/486 test creates `C:/Browse/Sub`, `Main.HC` and `Other.HC`, then
checks the exact VGA listing through both absolute and relative paths and verifies
that a missing path returns `-1`. It opens `EdDir("C:/Browse")`, checks exact VGA
frames while moving Down and Up, enters `Sub`, returns to its parent with
Backspace, opens `Main.HC` through `Ed`, and returns to the picker and prompt. Ten
native commands pass at 44.670-second startup. The expanded workflow then presses
`N`, enters `New.HC`, edits and saves `6*7;`, checks the refreshed selection and
reads back the exact document bytes. It reopens the picker, selects `New.HC`,
presses Delete, verifies the exact confirmation frame, accepts with `Y`, checks
the refreshed selection, and proves both `DocRead` and a repeated `FileDel`
report absence. Fourteen native commands pass at 46.729-second startup. Delete
rejects directories and publishes the tombstoned directory record before freeing
the file extent. Wildcards, rename, sorting and the original directory browser
remain open.

Rename validates both task-relative paths, requires one volume and parent,
rejects missing sources and collisions, and flushes the changed file or directory
record without reallocating data or changing directory parent links. Empty-directory
delete requires a valid terminator and no live entries after `.` and `..`, flushes
the parent tombstone, then releases the directory extent. The ABI-29 service
record is 64 bytes and appends directory delete after rename. The
complete build gate validates the directory-list function address, rejects
wrong-target, missing-import and wrong-ABI module mutations, and passes both
native x86-64 rebuild generations plus normal and diagnostic native boots.
