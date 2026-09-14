# Retained file services and disk-backed compiler includes

`FileRuntime.t32m` packages native path construction, filename rules, archive
expansion, decoded file loading, drive-context routing and the compiler file-input
bridge outside the conventional-memory bootstrap. The kernel loads it from RedSea
into the extended-memory heap and retains its image for the kernel lifetime.
The six linked bootstrap modules are unchanged in number. Ten modules are now
packaged: those six, retained CompilerRuntime and FileRuntime, and temporary
Startup and CompilerProbe.

## Interface and ownership

CI386FileServices version 10 is a 32-byte i386 record: version/byte-count fields,
a current-task include callback, a decoded-read function, volume binding and
root task-state initialization, compiler configuration and current-task control
construction.
Initialization writes a caller-owned candidate. The kernel validates the version,
size and all six addresses before publication; the host independently compares
them with export offsets. The retained image owns canonical channel gates and I/O
tables, initialized by the root-only binding service.

The module imports eighteen kernel functions: the existing nine heap/interrupt/
RedSea/lexical functions, plus RedSea begin/end/validation, the three shared ATA
protocol functions and scheduler block/wake/yield. It retains its string/codec
code and task/session adapters, with no duplicate PIO protocol or allocator.
The kernel publishes 40 explicit resident bindings.

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
| CompilerRuntime, retained | 256216 | 256232 |
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
