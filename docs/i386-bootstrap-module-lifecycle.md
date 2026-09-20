# Shared bootstrap module lifecycle

The resident kernel now shares three private helpers across startup, retained
service loading and temporary diagnostics:

- `KernelModuleLoad` resolves a volume path and loads the bound Main entry. The
  caller still owns boot-time disk access, bindings and acceptance policy.
- `KernelHeapCheck` checks expected used bytes and allocation count, plus heap
  structural validity.
- `KernelModuleRelease` frees an optional image, clears its caller-owned pointer
  and verifies caller-supplied expected totals under IRQ masking, then restores IF.

The expected totals remain specific to each lifetime. Retained-service rejection
uses the snapshot taken before loading or executing the module, so callback leaks
cannot be hidden by deriving expectations from the post-callback heap. Diagnostics
require unchanged heap totals on every successful invocation and reclaim exactly
the loaded image after their worker phase. Startup deliberately permits its
persistent display allocation and checks that only the startup image disappears.
The retained compiler and file images are still checked after diagnostic release.

Module service-table validation, versions, import binding, publication and error
markers stay at their existing callers. No service ABI or reserved load-area
change is involved. Normal boot continues to skip the diagnostic module. Sharing
this code recovers bootstrap space needed for the remaining public-kernel work;
it does not implement interruption coordination or the DolDoc environment.

Validation uses both x64 rebuild generations and the full native kernel suite,
including normal/diagnostic startup, exact VGA and console execution, startup
recovery, invalid diagnostics during normal boot and all existing incompatible
module/reclamation cases. Measured image size and results are recorded in
`port-progress.md` after execution.
