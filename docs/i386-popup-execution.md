# Popup execution as a GetStr prerequisite

The original GetStr path can replay the selected document entry on Escape.
That requires the complete DocEntryRun body, including popup macros and real
list/menu selection. The existing dependency audit in PLAN.md requires those
services before binding DocEntryRun; missing branches must not become stubs.

This slice implements the kernel PopUp execution service. It does not implement
PopUpMenu/PopUpPickLst, DocMenu, selected-entry replay or GetStr itself.

## Shared execution and native ownership

Kernel/Job.HC now includes Kernel/PopUpCore.HC. Both targets use the original
servant creation, TaskExe flags, JobResScan, result and output-pointer behavior.
A nonnull parent selects synchronous execution: publish popup_task, submit a
wake/focus-master request, collect the result, retire the servant and clear the
output pointer. A null parent is asynchronous and retains the returned task
pointer after retirement; Spawn's existing Seth-parent policy applies.

The native adapter uses the real retained SrvCmdLine and task/job providers.
It registers child identity and previous popup ownership in the common cleanup
stack before submitting work. Ordinary unwind requests child retirement without
yielding from cleanup and restores valid previous ownership. Successful async
handoff detaches the child. No callback, menu or execution branch is replaced
with a canned result. Cancellation and arbitrary foreign output-pointer lifetime
qualification still require dedicated tests; code structure alone is not proof.

Console 90 adds public PopUp at index 228, raising the public export count to 229. The private console service table
remains 48 bytes and Memory remains version 25; public CTask layout is unchanged.

## Paired contract

```sh
python3 tools/test-i386-popup-execution-reference.py --out REF
python3 tools/test-i386-popup-execution-reference.py --current-system --out SHARED
python3 tools/test-i386-popup-execution.py IMAGE --out NATIVE
```

The pinned original passes five explicit observations in
`build/i386-c1-popup-execution-reference-fixed/result.json`: result42 with cleared
sync output/ownership; negative and full 64-bit results; a live async child after
return; its completion/retirement with the original stale async output pointer;
and repeated exact caller-heap recovery. Inputs are unchanged.

Async code uses explicit addresses for its release/value fields. The first
fixture incorrectly assumed a null-parent child could resolve caller globals;
the original Spawn defaults to Seth, so that prototype was stopped and replaced.
The corrected fixture preserves the original default parenting rather than
changing the service to fit the test.

`build/i386-c4-popup-execution-shared-reference/result.json` passes the same five
observations on the rebuilt original with the extracted core, with unchanged
inputs. The original compiler/kernel rebuild also passes. Its first extraction
attempt used a function-like macro unsupported by HolyC; the repair uses an
ordinary creation helper and object-like alias.

The Console-89 native red in `build/i386-c2-popup-execution-red-fixed/result.json`
rejects the missing public PopUp helper before any execution observations; its
inputs remain unchanged. Native Console-90 build/behavior results follow as they
finish. The focused contract does not qualify popup chooser UI, focus recovery,
caller cancellation, all task ownership or full desktop compatibility.

## GetStr remains open

`build/i386-c2-getstr-console89-red/result.json` freshly rejects the GetStr
helper definition with unchanged inputs. Its thirteen scripted input cases do
not execute. The unchanged TimeClock source remains blocked at its GetStr call.
Next dependencies include real popup menu/list selection and full entry-action
integration, then original GetStr and its input/lifetime/reference gates. C1–C5
remain incomplete.

## Additional routing and startup boundary

The first built Console-90 image executes PopUp and returns mask 1, but its
native framebuffer gate fails because the document-less child's scalar answer
also appears in Root. Evidence: `build/i386-c2-popup-execution-green/result.json`
and its captured `startup-command-07.ppm`, with unchanged inputs. Native
ConsoleAnswer now records the job return value and omits presentation when
DocPut is null, matching the existing null-document public stdout sink. The
servant checker no longer expects ten leaked answer lines in Root; it still
requires the full startup mask and actual job results.

The original default servant startup remains incomplete natively: its document,
border/menu and real right-click callback require the full DocTermNew path.
The earlier mask-62-versus-63 startup gate remains open. This popup execution
slice does not qualify that startup or replace it with a field-only document.
It advances the real execution dependency while keeping menu/list/entry-action
and GetStr work explicit.

Both preceding candidates now pass all 214 unpaused editor/help/navigation
commands: `build/i386-c2-terminal-palette-private-views/result.json` and
`build/i386-c2-persistent-window-private-views/result.json`. Their source-image
provenance reports remain unchanged. These results qualify their pinned images,
not the new Console-90 candidate.

The first native extraction also rejected the public-name alias cleanup at
PopupRuntime's end (`Undefined identifier NativePopUp`). A dedicated
POPUP_FUNCTION name hook avoids that preprocessing path. This is not a claim
that native macro undefinition parity is qualified; keep a focused C4 check
before relying on that pattern. The final original-system control is
`build/i386-c4-popup-execution-shared-reference-final/result.json`.

## Qualified execution checkpoint

The final candidate is `build/i386-c2-popup-execution-cross-routing/kernel.img`.
Its original bootstrap, cross-build and limited 386 boot audit pass, with all
1475 source/build input hashes matching. The shared original control in
`build/i386-c4-popup-execution-shared-reference-final` passes all five observations
with unchanged inputs.

`build/i386-c2-popup-execution-green-routing/result.json` passes thirteen native
commands with unchanged inputs and exact Root framebuffer observations. Synchronous
42, negative and wide results, async handoff/retirement, repeated caller-heap
recovery and continued input all pass. The prior prototype's extra child answer
line is absent without suppressing the actual returned job value.

`build/i386-c2-popup-execution-startup-routing/result.json` passes nine normal
8 MiB startup commands in 48.589 seconds, with WinMgr enabled and no build-provider
loads. This does not qualify every 8 MiB child-spawn workload.

The corrected job checker now selects Execution.HC for its self-queue flag rather
than erroneously running Worker.HC under a self-queue description. The actual
8 MiB self-queue run passes 21 commands in
`build/i386-c2-popup-execution-self-job-regression`. Ten jobs still return 42;
self-directed results remain visible. The 64 MiB spawned-worker run passes 24
commands in `build/i386-c2-popup-execution-job-regression-64m`, with exact fixture
bytes and unchanged pins. A separate original worker control passes mask 63.

The spawned-worker fixture fails at 8 MiB before observing job results, with a
0x40508-byte allocation rejection. The preceding Console-89 image fails at the
same allocation in `build/i386-c2-popup-execution-job-baseline-8m`, so this is a
pre-existing minimal-profile gap. The checker's default stays 8 MiB; explicit
`--ram-mib 64` covers the planned full-desktop profile. Fresh final-checker runs
also add fail-fast INPUT REJECT handling, rather than reporting an allocation
rejection as a framebuffer timeout. Preserve the failing 8 MiB evidence; do not
infer child-spawn capacity from the passing minimal startup gate.

Caller cancellation/Exit, previous-popup ownership, child faults, complete
servant terminal startup, popup menus/lists and GetStr remain unqualified.
Null-document scalar routing is repaired; redirected/silent/filter-aware scalar
answers and general diagnostic routing are not qualified by this check.

Final checker runs: `build/i386-c2-popup-execution-job-final-64m` passes all 24
native worker commands with exact fixture bytes and unchanged pins;
`build/i386-c4-popup-execution-worker-original-final` passes the original mask-63
worker contract. `build/i386-c2-popup-execution-job-final-8m` now fails immediately
at the known guest allocation rejection, preserving its 8 MiB default. The
checker reports the original runner's actual 2048 MiB configuration separately
from the explicitly selected native RAM profile.


The [Console-91 lifetime follow-up](i386-popup-lifetimes.md) qualifies previous-owner
restoration and two caller termination paths, then repairs a stale completion
left for a recovered caller that remains alive. The stronger 24-command gate
passes; general foreign-master/output-owner/fault and complete UI startup still
remain open. The first 18-command pass alone did not cover this queue leak.
