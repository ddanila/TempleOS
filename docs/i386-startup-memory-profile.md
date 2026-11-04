# Startup allocation failure and shared lifecycle code

The C1–C5 image at 8d220f66 fails normal 8 MiB startup before the first command.
The complete workload and guest RAM limit are retained while investigating it.
The public drive/directory cases at 64 MiB do not establish minimal-profile
startup, native generations or full OS compatibility.

`profile-i386-startup-memory.py` boots a snapshot of the supplied image on
TCG `486,-fpu` with 8 MiB, waits for startup completion or kernel failure, stops
the CPU, and saves all guest RAM. It resolves `kernel_heap` from the exact
embedded kernel module and boot metadata, validates each physical block, and
checks live block counts/bytes against the heap control. Allocation-size totals
are observations, not call-site attribution. Failure return addresses are
resolved against loaded module ranges; the report retains both addresses and
symbol matches. A captured failed boot is reported as `captured` with
`boot_failed: true`, never as an OS pass. This is not a timing benchmark.

The kernel now enables the existing no-allocation failure caller trace.
`build/i386-c4-startup-caller-cross` builds with all current-at-capture inputs,
574856 kernel bytes and the limited 386 boot audit. Its stopped guest capture is
`build/i386-c4-startup-caller-profile`: raw heap usage 6611240 of 6633984 bytes,
largest free payload 8672, and 187600 bytes of block headers/alignment beyond
requested payloads. The failed 9480-byte request resolves to
`MemoryRuntime:TaskRuntimeTaskCreateFrom`, called by `MemoryRuntime:Spawn`.
The log reaches `STARTUP source ok` before the failure; the next source operation
is NativeKeyboardStart's 8192-byte-stack worker. This identifies task creation,
not command parsing, as the immediate failure.

An independent read of the captured MemoryRuntime `memory_pool` export gives
832512 public page-pool bytes allocated and 824832 used: only 7680 free. The
largest raw allocations are resident Console, Compiler, File and Memory service
images. Reducing the held public startup reserve is not supported by this
capture. The profiler preserves the source disk and records hashes of the
input tools, exact embedded modules and RAM dump.

The prior memory provider compiles a second scheduler/lifecycle implementation
through TaskRuntimeCore.HC. Its TaskRuntime-prefixed functions occupy 55608 bytes
in the captured module. The candidate removes that include from MemoryRuntime
and imports the kernel's I386TaskCreateFrom, I386SchedActivate, I386SchedFinish
and I386TaskDestroy. Public Spawn, Exit, task queues, jobs, ownership, cleanup,
exceptions and message logic remain in the provider. The kernel already uses
these same lifecycle routines; this change shares their implementation rather
than disabling task behavior or reducing stack sizes. The retained reference
core remains available to its independent foundation tests.

Memory service version 27 and four explicit imports require a matching kernel.
The host import validator checks the expanded contract. Three lifecycle kernel
exports are added; destruction reuses its existing export. Caller tracing stays
enabled to identify subsequent failures. Original bootstrap rebuilding passes;
current native startup and public-task validation are recorded below as they
complete. All C1–C5 completion gates remain open.

The candidate cross build is `build/i386-c4-shared-lifecycle-cross`: kernel
575184 bytes, 1484 source and 24 build-input hashes matching, and the limited
96-BIOS/255-protected-instruction audit passing. The exact module comparison in
`build/i386-c4-shared-lifecycle-footprint.json` measures a 55608-byte reduction,
zero TaskRuntime-prefixed local function bytes, and all four required lifecycle
imports. The separate public-pool observation is recorded in
`build/i386-c4-startup-caller-profile/public-pool-audit.json` with module/RAM hashes.

`build/i386-c4-shared-lifecycle-startup-8m` completes all nine functional commands:
retained code/static state, literals, arithmetic, graphics activation, and exact
text/graphics VGA restoration. It acquires no build provider. The overall gate
is still **fail**: startup is 64.978408 seconds, exceeding the unchanged 60-second
limit. The memory failure is resolved for this workload, but the minimal profile
is not qualified. Public lifecycle tests use an explicit 64 MiB option; their
existing 8 MiB defaults and behavioral assertions are unchanged. An older-image
accounting control runs separately to distinguish existing failures.

Public cancellation passes all 69 commands at 64 MiB in
`build/i386-c4-shared-lifecycle-kill`; message posting passes all 44 commands in
`build/i386-c4-shared-lifecycle-messages`. The first covers pre-entry/running/
sleeping/suspended tasks, callback recovery, caller Break, Shift-Esc delivery and
invalid targets. The second exercises real public message queues and routing.
Neither is a replacement for task-accounting or minimal-profile qualification.

The statistical boot profile `build/i386-c4-shared-lifecycle-boot-profile`
reaches startup completion. I386HeapScanSelect accounts for 181/241 root-header
samples, 33/135 foundation samples and 7/11 startup-source samples. Sampling
pauses invalidate timing comparisons. This points to the full raw-heap validator
as the next performance target, not to shrinking the workload. Its existing
whole-chain corruption/rejection guarantees must remain covered by the heap
regression corpus.

Both long accounting runs reached the oversized-stack rejection and timed out
there (`build/i386-c4-shared-lifecycle-accounting-control` and
`build/i386-c4-shared-lifecycle-accounting`). The harness had kept an 8 MiB stack
request while selecting a 64 MiB guest; that request no longer guaranteed
OutMem. All preceding sequential assertions completed in both runs, including
normal/Exit, deferred activation, descendants, exceptions, end callbacks and five
invalid-creation cases. This is not a full accounting pass. The corrected harness
requests the selected RAM size as stack payload, which cannot fit alongside its
record and resident OS, and retains all rejection/recovery assertions. Default
8 MiB behavior is unchanged. Corrected full control/candidate runs use the
`-ram-bound` artifact suffix and remain pending until their final verdicts.


## Eight-MiB heap census after default servant restoration

`tools/observe-i386-heap-pressure.py` captures both physical allocator arenas
at normal startup and after actually requesting `/Kernel/SymbolTypes.HH`.
It uses a disposable image copy, an explicit 8 MiB KVM 486 without FPU, the
normal welcome and WinMgr startup, and paused QMP physical-memory snapshots.
Every block is checked for valid span, alignment, tag, reserved field and
requested size. Full block lists, raw snapshots, size histograms, screenshots,
command logs and unchanged input hashes are retained. Its `result=pass` means
that observation succeeded; `header_accepted` separately reports the workload.
The shared Guest helper retains its existing 64 MiB default.

The baseline `build/i386-heap-pressure-before-v1/result.json`, using
`build/i386-autocomplete-popup-cross-v3/kernel.img` (SHA-256
`d49755907e5268d624e85e65ef03ba5bf6c10738b66520e51f1699b7b5969c38`),
passes observation with unchanged pins but **rejects the header with OutMem**.

| Arena / phase | Capacity | Used spans | Allocations | Free spans | Largest free payload |
| --- | ---: | ---: | ---: | ---: | ---: |
| Main / startup | 6,649,344 | 6,618,872 | 14,216 | 30,472 | 8,952 |
| Main / rejected header | 6,649,344 | 6,626,888 | 14,224 | 22,456 | 4,752 |
| Fallback / startup | 551,936 | 543,664 | 7 | 8,272 | 6,936 |
| Fallback / rejected header | 551,936 | 549,808 | 13 | 2,128 | 792 |

All sizes are bytes; used/free spans include allocator headers. Largest free
payload excludes its header. The main arena's two largest requested allocations
are the compacted ConsoleRuntime (2,698,408) and CompilerRuntime (1,543,656).
The console's retained raw planar surface requests another 153,600 bytes;
public graphics backing also occupies both arenas. This is physical pressure,
not evidence that the requesting public data heap itself holds all RAM.
At startup 14,216 live main-arena allocations request 6,338,770 bytes, with
280,102 bytes of headers/alignment overhead.

The census does not justify aliasing display storage: each raw terminal retains
its planar pixels, while graphics presentation has a distinct lease and frame
ownership protocol. Any sharing would need to preserve those semantics and
pass text/graphics/focus restoration and popup raster regressions. No allocator,
RAM limit, workload, or display ownership policy changes here. The 8 MiB
servant contract, complete minimal profile and C1-C5 gates remain open.
