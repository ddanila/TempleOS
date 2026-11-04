# Worker diagnostic provider lifetime

The diagnostic worker's memory probe uses an isolated public backing pool while
preserving its real public pages and control. Its following compiler checks use
a temporary CompilerProbe module. Loading that module before root header
publication kept 554,020 retained module bytes (554,040 raw heap bytes) live throughout
the independent worker memory probe. The previous full 8 MiB run stopped when
that probe requested 131,000 bytes.

The second CompilerProbe load now occurs immediately after the worker memory
probe, before the compiler checks that use it. The worker wraps the load in a
volume transaction with IRQ save/restore, matching the later worker program
provider's existing protection. The first root load remains before console
allocation. Provider validation, full retained file capacity, reclamation,
worker's 1 MiB private arena and 16 KiB stack, all probe workloads and physical
RAM are unchanged. No memory allocation or assertion is reduced.

`PROBE LOAD` records each provider's address, retained capacity and raw heap
span. The full-gate verifier checks these against the existing execution/release
records and requires the second load after the completed worker memory probe.

## Evidence

- `build/staged-worker-probe-rebuild-v2.log`: two original bootstrap generations
  pass. This is not C5's native release-generation qualification.
- `build/i386-staged-worker-probe-minimal-v1/source-audit.json`: all 1,361
  delivered source/document files match the candidate; 386 boot audit also passes.
- `build/i386-staged-worker-probe-smoke8-v1/budget.json`: unchanged normal 8 MiB
  KVM 486 without FPU startup workload passes in 33.48 seconds, below 60 seconds.
  Live welcome/WinMgr, arithmetic/public input-state pixels and provenance pass.
- `build/i386-staged-worker-probe-minimal-v1/failure.json`: the unchanged complete
  default 8 MiB gate still **fails**, but both memory phases now pass their
  preservation, isolated-pool, cleanup and teardown checks. The worker's real
  control retains 16 live bytes and 8,192 allocated bytes exactly as before.
  The second provider subsequently loads at 0x722010 with the same capacity and
  span as the root provider. Worker parser and conditional-pressure tests run;
  the terminal stop is immediately after `RESIDENT START` phase 1, kind 0.

All 15 non-kernel module files are byte-identical to the preceding frame-load
candidate (`module-comparison.json`). Only Kernel.t32m changes. The failure
report pins images, relevant sources and terminal logs. The first resident case
contains several assertions, so its exact cause is not yet established. No
worker compiler completion, full minimal suite pass or C1-C5 completion is
claimed. This staging change resolves the previous worker memory overlap;
remaining resident-source and subsequent gates stay open.
