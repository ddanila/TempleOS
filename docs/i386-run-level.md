# Shared startup stage flags

The native kernel owns one original-width U32 run-level record. Console ABI 207
borrows its address through CI386ConsoleConfig; the public `_SYS_RUN_LEVEL`
binding and original raw-output core use that same record. The console has 577
bindings and a 19-word data bitmap. The previous private I64 raw-output-only
value is removed.

Flags are published at actual readiness boundaries, with a trace of each update:

| Stage | Publication boundary |
| --- | --- |
| 16-bit, VGA, 32-bit | Entry through the native BIOS/protected-mode loader |
| Compiler | Validated retained compiler, symbols and public math bindings |
| Block devices | Boot volume and retained file services initialized |
| Raw output | Raw rendering tables and console storage initialized |
| Adam server | Root job-handler callback validated before entering its dispatch loop |
| Interrupts | Console task enables interrupts before startup compilation |
| Documents | Actual DocInit completes |
| Registry | Adam-owned registry initialization returns with the correct owner |
| Window manager | Actual worker initializes its document definitions and enters its loop |

Normal startup ends at 0x4F707 (325383). Architecture-specific patching, 64-bit,
16 MiB block-pool and multiprocessor flags are not asserted. The original full
block-pool heap stage also has no qualified native counterpart yet. Home,
Once-Adam, Once-User and autocomplete flags remain clear until their actual
workflows are integrated. Flags record initialization stages, not current task
liveness; a window-manager restart does not erase its earlier stage.

The contract checks every transition and ordering boundary, the U32 public type
and export address, and a real spawned child's read/write of the shared record.
It restores the temporary autocomplete bit before checking resumed console
input. No autocomplete task is activated by that test.

CHashExport is now shared verbatim through HashExportTypes.HH and included by
PublicHash.HH and the original SymbolTypes.HH. This provides the actual original
export record without loading unrelated compiler symbol classes merely to
inspect an export value. No declaration fields or assertions were removed.
The initial 8 MiB fixture loaded all SymbolTypes.HH and exhausted its arena;
that attempt is not a pass. An earlier fixture attempt omitted the export type
include. The final 64 MiB contract passes mask 7, exact stage transitions and all
framebuffer checkpoints (`build/i386-run-level-native64-v3/result.json`), with
startup at 42.44 seconds. The full contract still exhausts the kernel heap at
8 MiB during compilation (`build/i386-run-level-native8-v2/result.json`); it
remains a failed resource gate. Neither the header extraction nor normal startup
is presented as an 8 MiB full-contract pass.

Two original rebuild generations pass after the type extraction
(`build/run-level-rebuild-v3.log`). The final image passes the
full thirteen-case original raw-output oracle, including persisted state,
cache and hardware plane bytes (`build/i386-run-level-raw-output64-v2/result.json`).
The image passes the 386 instruction audit and all 1,255 packaged candidate
source/documentation files match independently
(`build/i386-run-level-cross-v2/source-audit.json`).
The raw-output checker now accepts explicit accelerator and welcome-document
options; its original defaults and all oracle comparisons remain intact.

The real-service unchanged MakeAC probe passes the run-level and keyboard-state
dependencies and rejects missing Size at ACInit.HC line 116
(`build/i386-run-level-autocomplete-v2/result.json`, unchanged input pins).
That failed probe does not qualify initialization, dictionary loading or visible
suggestions. Full application, minimal-profile and C1-C5 qualification remain open.

The rebuilt-original reference also passes mask 7 for the U32 export, actual
compiler/block/document/registry readiness, and a spawned child's shared read
and write (`build/i386-run-level-reference-v2/result.json`). At its Once hook the
observed original flags are 0x1FFFF; the Adam-server flag is still clear because
KMain publishes it after StartOS returns. The native root serves startup registry
jobs, so its Adam stage becomes ready earlier. Each profile records its actual
lifecycle rather than copying the other profile's final word. The first reference
attempt incorrectly expected Adam readiness at that original hook and failed;
its width and shared-write observations passed, but the attempt is not a pass.
