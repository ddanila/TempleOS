# Task-owned RedSea sessions

`CI386RedSea` now carries an optional borrowed `CI386RedSeaIo` table. Mount
initializes it to null, preserving the quiescent boot path. A bound volume routes
all RedSea sector reads, writes and flushes through the table. This includes
partial-sector writes, bitmap allocation/free, directory publication, replacement
and deletion; on-disk layouts and lookup order are unchanged.

## Ownership boundary

`I386RedSeaTaskIoInit` attaches initially zeroed I/O storage to one canonical ATA
channel gate. `I386RedSeaTaskBind` attaches that table to a mounted volume only
from root, with IF clear and the channel idle. Both drives and every task-visible
volume on the channel must share this gate. The table, gate, scheduler, disk
profiles and volume records remain live and stable. There is no unbind/unload
operation, and raw boot I/O must not run concurrently on a bound channel.

A caller brackets a complete metadata/data operation with `I386RedSeaBegin` and
`I386RedSeaEnd`. The lease covers both drives on the channel; a reader cannot
enter while a writer is between sectors or updating directory/allocation state.
Sessions do not nest. The lower-level RedSea functions reuse the caller's lease
through `I386AtaTaskOwned`, which verifies ownership without reacquiring it.
Unleased bound I/O fails before issuing a hardware command. Empty operations may
complete without I/O. Root cannot block on another owner.

`I386RedSeaFileRead` and `I386RedSeaFileLoad` manage this session automatically,
including failure cleanup. Their IF-clear calling convention is unchanged.
`I386RedSeaReadAll` is the inner owned-buffer primitive and requires an existing
session on a bound volume. Directory/extent/allocation/mutation primitives also
require an outer session. Bound-volume module loaders likewise need an outer
session; the current boot loads precede binding. Callers must release on every exit
and must not cancel or unwind exceptions through a held session. Public task/file
exception cleanup is still a later integration requirement.

The ATA adapter opens interrupt windows and yields at polling boundaries while
retaining the lease. A touched failure poisons the whole channel; the outer file
operation then reclaims its temporary buffers and releases the task pin. Queued
requests drain without I/O, and later requests fail. There is no reset recovery
API yet. A failed write may already have changed disk sectors; session exclusion
is not crash atomicity or power-loss durability.

## Retained integration

FileRuntime service version 2 adds a volume-binding function. Its retained image
owns two canonical channel gates and two I/O tables. The standalone kernel binds
its mounted C volume after boot-time compiler/probe/startup module loading and
before starting the keyboard and pulse tasks. Boot-time includes use quiescent
I/O; the pulse task's nested plain/compressed includes use the bound session path.
Both paths preserve the existing 68-line result, malformed-archive behavior and
temporary reclamation. Explicit IF-set calls remain rejected by the file bridge.

The drive/path and compiler contexts are still explicit private records. This
change does not provide public CTask/CDrive binding, independent task directories,
resident-file semantics, public filesystem exceptions or a complete HolyC shell.

## Verification

`python3 tools/test-i386.py --ata-tasks` now includes two mounted RedSea volumes
on the same channel. It rejects unleased read/write/flush and nested sessions,
queues a reader behind a two-sector writer, verifies the complete new contents,
reads the other drive's unchanged file, and reclaims owned file/task allocations.
A file read then succeeds for its first sector and receives a device error for
the next: read-all frees its temporary buffer, preserves the caller's size,
poisons the channel and cancels the other drive's queued request. The host checks
the complete command suffix and both 16 MiB backing images, permitting only the
explicit raw and file-sector writes. The fixture uses a 256 KiB test loader with
its heap starting at 0x50000; this does not change the standalone bootstrap limit.

The standalone boot test checks version-2 service ownership and all three function
addresses, volume binding before task activity, successful disk includes in both
phases, IF-set rejection, module lifetime/reclamation and unchanged disk contents.
These remain QEMU 486/8 MiB development checks. Strict 386 hardware validation,
wall-clock service latency, reset recovery and complete application workflows are
not established by these tests.

The two-generation x64 rebuild and native `--ata-tasks`, `--redsea-read`,
`--redsea-write`, `--redsea-alloc`, `--redsea-create`, `--redsea-delete`,
`--redsea-replace`, `--redsea-load-set` and `--redsea-bind` checks pass, along with
`tools/build-i386-kernel.py --test`. The allocation and fixed-write fixtures now
use the existing 128 KiB test-loader profile to accommodate dispatch code. The
standalone bootstrap is 387,432 bytes and retained FileRuntime is 96,144 bytes
(96,160 heap bytes). Its 384 KiB bootstrap reservation is unchanged.
