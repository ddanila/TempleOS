# Retained file services and disk-backed compiler includes

`FileRuntime.t32m` packages native path construction, filename rules, archive
expansion, decoded file loading, drive-context routing and the compiler file-input
bridge outside the conventional-memory bootstrap. The kernel loads it from RedSea
into the extended-memory heap and retains its image for the kernel lifetime.
The six linked bootstrap modules are unchanged in number. Ten modules are now
packaged: those six, retained CompilerRuntime and FileRuntime, and temporary
Startup and CompilerProbe.

## Interface and ownership

CI386FileServices version 2 is a 20-byte i386 record: version/byte-count fields,
an include callback, a decoded-read function and a volume-binding function.
Initialization writes a caller-owned candidate. The kernel validates the version,
size and all three addresses before publication; the host independently compares
them with export offsets. The retained image owns canonical channel gates and I/O
tables, initialized by the root-only binding service.

The module imports eighteen kernel functions: the existing nine heap/interrupt/
RedSea/lexical functions, plus RedSea begin/end/validation, the three shared ATA
protocol functions and scheduler block/wake/yield. It retains its string/codec
code and task/session adapters, with no duplicate PIO protocol or allocator.
The kernel publishes 35 explicit resident bindings.

The boot configuration borrows one mounted volume in drive slot C, a root current
and home directory, and the original whitespace bitmap. Its stable path/volume
context is passed to the include callback; the module does not retain an implicit
current task. Both code images, the context and referenced volume/heap must remain
live while calls use them. Kernel shutdown is the current image lifetime; general
module unloading and arbitrary task-owned callbacks remain separate work.

Failed module loads and incompatible returned interfaces reclaim their allocations
and preserve the pre-load heap baseline. Three boot mutations exercise a wrong CPU
tag, unresolved import and wrong service version. They must halt before compiler
probes/startup, with no file interface published. Disk contents remain unchanged.

## Connected compiler path

CompilerProbe's version-2, 48-byte borrowed record now includes the disk provider.
At boot, its version-10 retained lexer reads a root include directive, calls the
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

Calls retain their IF-clear convention. After boot-time module loading and startup,
the kernel binds C to the runtime's canonical channel gate before starting tasks.
The task-phase probe now performs the same nested disk reads and archive-error
cleanup as the boot probe. Polling yields with the file session still owned.
It also explicitly enables IF and verifies rejection before disk access, then
restores its original flags. See [i386-redsea-tasks.md](i386-redsea-tasks.md) for
session scope, cancellation restrictions and remaining public integration.

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
connected disk includes, malformed-archive recovery, enabled-IF rejection, image
lifetime/reclamation, all module rejection cases, source checks, VGA/keyboard/timer
checks, unchanged disks and executable-region instruction audits across all ten
modules. This remains an 8 MiB QEMU/486 development result.

Current images and allocations:

| Component | Image bytes | Heap bytes |
| --- | ---: | ---: |
| CompilerRuntime, retained | 138664 | 138680 |
| FileRuntime, retained | 96144 | 96160 |
| CompilerProbe, reclaimed after task check | 68680 | 68696 |

The native bootstrap is 387432 bytes. With its 2160-byte loaded stage overhead,
389592 bytes occupy the unchanged 393216-byte reservation, leaving 3624 bytes.
The separate 512-byte boot sector is excluded from that reservation. Further
bootstrap growth needs extraction or reduction; the low-memory reservation has
not been raised. These are measured artifacts built with local changes before
commit; manifests record revision and source hashes.

Public task/drive binding, resident-file caching, public errors/exceptions,
reset recovery and latency measurement, full compiler-control lifetime, parser/JIT,
DolDoc and persistent editing, strict 386SX/DX profiles and native self-hosting
remain open. The connected include path is a compiler prerequisite, not a claim
that the full native programming environment is complete.
