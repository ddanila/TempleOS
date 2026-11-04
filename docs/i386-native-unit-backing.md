# Native source-unit cleanup and retained backing

The full 8 MiB diagnostic stopped after executing the native allocation-loader
fixture. Temporary allocation-free checkpoints in
`build/i386-native-alloc-stage-minimal-v2` isolate the failure: source compilation,
module packing/loading, reserved-field corruption rejection, the valid load,
entry result 42, malformed-module rejection, inner frees, outer frees and all
six scalar-type removals succeed. The final bare physical-heap comparison sees
8,976 extra bytes in one allocation. `observation.json`, the boot log and the
saved instrumented source retain this failed attempt; it is not a full-gate pass.

Public executable storage uses a heap that can retain allocation pages after
live code is freed. Its backing regions are allocations in the physical heap,
so comparing only that heap's raw counters conflates retained backing with live
payloads. The enclosing program probe, kernel caller, header probe and format
probe already use `I386BackingCheck` to distinguish them.

Ten source-unit cleanup checks now use the same existing save/restore helper:
integer math, archive control/expansion, native expansion, packer, bundle,
loader, allocation loader, file loader and creator. The helper verifies exact
public live-byte recovery, unchanged pool/control identity, valid owned regions
and their physical spans, and exact recovery of physical bytes/counts after
subtracting only verified backing ownership. If the compiler arena is separate
from the backing arenas, its full raw bytes and allocation count must recover
exactly. No allocator policy, RAM limit, worker budget or source workload changes.

The allocation-loader records public-live and backing before/after values, and
the full host verifier requires the new record and equal live values in both
root and worker phases. The two six-byte synthetic `MOV EAX,42; RET` fixtures
now declare U32 returns, matching their actual 32-bit machine ABI. Their packed
61-byte fixture and 16-byte loaded-image checks remain unchanged.

## Evidence

- `build/native-unit-backing-rebuild-v1.log`: two original compiler/kernel rebuild
  generations pass. These are bootstrap evidence, not the C5 native rebuild gate.
- `build/i386-native-unit-backing-unit-evidence-v1`: preserved completed results
  for the complete three-runner portable heap corpus and assembly/portable
  backing-accounting tests, with corpus/source hashes. Fault injection rejects
  physical and public live leaks, private-compiler-arena leaks, corrupt retained
  totals, bad region spans/counts and invalid baselines without changing live
  bytes. Both ownership arrangements retain exact payload and IF checks.
- `build/i386-native-unit-backing-minimal-v1`: the complete default `--test`
  attempt now finishes the root compiler/program suite, native allocation/file/
  creation checks, public headers and their cleanup, then reaches foundation
  startup. Root allocation-loader accounting is:

| Quantity | Before | After |
| --- | ---: | ---: |
| Public live bytes | 790,720 | 790,720 |
| Verified retained physical backing | 826,920 | 835,800 |
| Owned backing regions | 5 | 6 |

The 8,880-byte retained-region increase in this final layout passes the existing
ownership checker and the enclosing program/kernel checks. Retained spans
include region metadata and page-alignment padding, so their exact size depends
on placement; the earlier instrumented layout recorded 8,976 bytes. The final
`PROGRAM PROBE complete 0`, module release, and `ROOT USER HEADERS ok` markers
are present. The 386 boot audit and 1,361-file delivered-source audit pass.

The full gate remains **fail**: worker creation requests 1,070,343 bytes, while
the physical heap has capacity 6,768,128, uses 5,826,784 and has a largest free
payload of 911,920 bytes. It records HEAP EXHAUSTED after
`READY native kernel foundation`. The existing one-MiB private worker arena and
stack budget are retained. Worker-phase and later gate checks have not run;
`failure.json` records this precise scope and input hashes. No full minimal or
C1-C5 qualification is claimed.

The first backing-accounting unit invocations were started while the bootstrap
rebuild manifest was absent and terminated before guest execution. The `-v2`
logs/results are the completed runs used above. The temporary detailed stage
traces were removed from production; the concise backing record is retained.

The separate normal 8 MiB KVM 486 without FPU smoke passes in 34.980346 seconds
under the unchanged 60-second limit, with live WinMgr/welcome and exact
arithmetic/public-input-state pixels
(`build/i386-native-unit-backing-smoke8-v1`). Its provenance, completed unit
provenance and scoped full-gate failure hashes remain unchanged after terminal
results. This smoke does not promote the failed worker/full-suite gate.
