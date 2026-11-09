# Task retirement with linked controls

Budget's nested calendar pickers exposed a task reclamation deadlock. All four
pre-fix calendar workflows stopped before `BP created-entry ready`, after the
outer schedule had been accepted. The caller waited in MemoryKill/NativePopupKill;
the schedule popup waited for its three finished picker children to be reaped.

The monthly stopped VM retains registers, 64 MiB RAM, a public-task analysis and
`retirement-state-v1.json` under `build/budget-recurrence-monthly-native-v1`.
The private records show children 7–9 finished, public signature zero and lifetime
references zero. Each still owns two linked scroll controls. Their heap and symbol
states retain the parent: three children in each, giving parent task 6 six
references. The low-level reaper correctly refuses a nonempty control queue.
This is separate from the earlier ATA late-save deadline overrun.

`NativeRenderOwnerRetire` now detaches the remaining window associations after
all descendants are gone and render borrowers have drained. It self-links each
control and clears `win_task` when it targets the retiring task, preserving IRQ
state. It neither frees caller-owned controls nor invokes callbacks. Task-owned
allocations are reclaimed with the heap. A recovering task-end callback runs
before committed retirement, so recovery leaves the associations intact. The
scheduler's low-level nonempty-queue guard remains unchanged.

The focused fixture `tests/guest/i386-control-retirement/Contract.HC` exercises
normal return, explicit Exit and external Kill with a throwing, caught task-end
callback followed by final Kill. Parent and leaf own scroll controls; a generic
control and its state belong to the caller. It requires actual child-list drain,
parent reclamation, intact borrowed state, a detached borrowed control with no
stale target, and exact caller heap recovery in each mode. The unchanged mature
fixture fails before the fix with masks 51/0/0 and passes afterward with
255/255/255. File bytes, attributes and timestamps remain unchanged; fresh
arithmetic renders 42. These are bounded per-mode checks, not a general resource
or mouse qualification.

```
python3 tools/test-i386-control-retirement.py IMAGE --out FRESH_OUT
```

Canonical evidence is `build/control-retirement-before-v2/result.json` and
`build/control-retirement-fixed-v1/result.json`. The early before-v1 prototype
has uninitialized results and is not the comparator. The fixed image is
`build/i386-control-retire-cross-v1/kernel.img`. Both existing bootstrap
generations and the 386 boot instruction audit pass. Only RenderScope.HC changes
among runtime sources; only ConsoleRuntime changes among sixteen module binaries.
Kernel bytes and public Compiler/Console/Memory ABI versions 104/264/41 remain
unchanged. Existing original bootstrap generations do not satisfy C5's two
successive native rebuild requirement.

The existing DocEd-exit and derived-control regression commands run through a
retained build-only adapter using KVM and the full-welcome observation profile.
It adds exact expected `Warning: Unused var` output for the existing unused
parameters, preserving guest command sources, fixtures, deadlines and pixel
comparison. Earlier wrappers that expected blank startup or omitted that warning
are preserved as failed observations, not cleanup-contract failures. See their
`execution-adapter.json` and the combined recurrence audit for final outcomes.

The derived-control regression now has passing explicit cleanup evidence at
`build/control-retire-derived-source-v2/result.json`: six masks all 63,
unchanged filesystem bytes/attributes/timestamps and fresh arithmetic 42.
Run it with:

```
python3 tools/test-i386-control-derived-lifecycle.py IMAGE --source-fixture --out FRESH_OUT
```

The option compiles the same thirteen definition commands from a generated file,
then calls the same DLRun modes 0–5 and exports their raw results. Its WinMgr
pause function is unchanged and runs before the first mode, inside the short
contract invocation. The default interactive execution remains available.
`build/control-retire-derived-source-audit-v1/result.json` compares every
definition and mode with committed revision fa030de4, verifies source/fixture/raw
pins and audits the preserved preceding failures. This qualifies the explicit
callback cleanup contract, not automatic control prepass or console input.

The legacy v3 driver stopped while typing DLFlow, before any DLRun call. Every
prior screen row exactly matches the expected raster shifted eight pixels left;
the console viewport/wrap compatibility case remains open. The first included
attempt paused WinMgr before typing its include, then observed INPUT RESET and
a truncated include before any cleanup call. The final option loads definitions
with WinMgr active and pauses inside the contract before callbacks. These are
preserved input/setup failures, not passing cleanup observations or fixed console
issues. No runtime module changed in this regression checkpoint.
