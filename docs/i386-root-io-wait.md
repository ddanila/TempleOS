# Root-task I/O contention

Adam/root file operations now wait for a busy native ATA channel instead of
returning failure. Root stays in the runnable ring, joins the same FIFO waiter
queue as other tasks, and yields through the raw scheduler until ownership
transfers. Existing queued tasks remain ahead of root. Worker blocking,
registration cleanup, public drive/device lock handoff, poisoned-request
suppression and the caller's original interrupt state retain their checks.
Recursive acquisition by the existing owner still fails.

This fixes an actual autocomplete dictionary failure. With the unchanged library
and all 95,293 words initialized, the native definition getters returned NULL
while the live autocomplete task held the drive/device locks. A diagnostic
recorded Adam at `0x102B20`, the owner at `0x1658210`, and both lock bits set
(`build/i386-acd-search-diagnostic-v7`). The channel explicitly rejected a
contended root acquisition. The bounded ATA regression reached return 8 on the
old implementation (`build/i386-root-ata-before-v5/runner.log`).

The complete ATA task suite passes after the change:
`build/i386-root-ata-after-v5/result.json` and `ata-task-check.json`. At 8 MiB on
QEMU 486, root reads a known sector only after both the current reader and the
already queued reader finish their first reads. The exact bytes, cleared wait
registration, I/O locks and restored IF are checked. A second root whole-file
read waits for a concurrent writer/reader and receives all 1,024 committed
bytes. All 64 worker pattern reads, two writes/flushes, existing file/task/module
stage cases, IRQ checks and poison/cancellation cases remain. The independent
host checker retains the exact command stream, including exactly one added root
sector read and the three commands of its whole-file read. Both final backing
images are compared byte-for-byte; a poisoned queued request must issue no
command. The 386 instruction audit also passes.

The old fixture itself first needed repair. RedSeaIo's real callback-unwind path
now requires exception services; the fixture omitted them and stopped in the
original debugger. It now links the actual SysTry/ExceptContext and exception
runtime, installs real services, and gives root its real runner stack bounds.
A caught compiler exception exports its document and fails immediately instead
of timing out silently. Exception-context assembly is audited as one complete
unit, following the existing exception-task fixture. No service is stubbed.

The fixture's 32 KiB private heap could no longer spawn its three 8 KiB-stack
workers. The current native owned-task record measures 1,264 bytes, and each
allocation also reserves page-alignment space. The fixture uses an explicit
64 KiB heap, retaining all workers and stack sizes and exact final heap recovery.
The machine still has 8 MiB RAM; this is not a change to the OS memory profiles
or qualification of the complete minimal suite. A separate FIFO-helper attempt
exceeded the unit runner's boot-loader limit; the final FIFO check runs during
the existing readers' first requests without dropping any workload.

Two original compiler/kernel rebuild generations pass
(`build/autocomplete-root-io-rebuild-v1.log`). The full native image at
`build/i386-autocomplete-root-io-cross-v1` passes the 386 audit and all 1,260
packaged source checks. Its unchanged dictionary contract passes actual root
loading, initialization, exact binary definitions and task stop/restart; see
[the dictionary evidence](i386-autocomplete-dictionary.md). This does not qualify
visible suggestions, all desktop workflows, full minimal regressions or C1-C5.

The separate 8 MiB normal-startup smoke passes in 42.26 seconds with live WinMgr/welcome,
arithmetic, public input timing/state and exact pixel checks
(`build/i386-autocomplete-root-io-minimal8-v1/result.json`), with unchanged
inputs. It remains a bounded smoke, not the full minimal regression suite.
