# Budget return diagnostics

The nested entry-picker workflow has one unresolved native timeout after entry
acceptance and saving, before `BP done`. Its final screenshot shows the console.
The three saved files equal successful runs, but no CPU/RAM snapshot exists for
that original failure. Successful repetitions do not establish a fix.

Two additional unchanged-fixture full commands, `build/budget-return-capture-native-v1`
and `-v2`, pass masks 1023/63 with real cold reopening. Their failure-only capture
wrapper changes no successful interaction. The earlier failed receipt remains
`build/budget-entry-picker-native-v2/result.json`.

`tools/profile-i386-budget-return.py` repeatedly opens the actual Budget UI on a
copy of a previously saved nested-entry image. Each session sends Shift-Escape,
requires caller restoration mask 63, checks the exact report and all saved fields,
compares every file's bytes/attributes/timestamps with the packaged baseline and
executes fresh console arithmetic. No installation, reseeding or application
callback injection occurs. Each session has a separate export/log directory;
previous export addresses are never reread after their session finishes.

On a failure, the profiler stops QEMU, records its CPU registers and saves all
64 MiB of RAM before closing the VM. The failed result includes capture hashes
and the original error. This is evidence collection, not failure recovery.

```
python3 tools/profile-i386-budget-return.py SAVED_ENTRY_IMAGE --runs 16 --out OUT
python3 tools/analyze-i386-task-capture.py OUT/round-NNN --image OUT/working.img --boot-log OUT/guest/debug.log --out ANALYSIS.json
```

The analyzer reads the stopped snapshot without changing it. It checks captured
`CTask` metadata against the published 992-byte layout, follows public task/hash
records and bounds caller chains by each task's declared stack. If the immortal
boot root lacks a public stack record, its caller chain is omitted. Functions
from the image's retained modules and dynamic public symbols provide nearest
symbol hints. It also records active render scopes and the WinMgr update count.
These hints locate a wait for subsequent source/disassembly review; they do not
by themselves prove a root cause.

`build/budget-return-repeat-native-v2/result.json` passes sixteen read-only
reopen/abort cycles with unchanged inputs. This exercises teardown after saved
entry loading. It does not reproduce the first close after nine entry/menu
popups. The observer retains export buffers in its caller, so these repetitions
are not an application heap-recovery qualification. The original timeout and
full Budget/C1–C5 acceptance remain open; bundled qualification stays 2/686.

The capture path is validated in
`build/budget-return-capture-check-native-v1/injected-failure-check.json`: an
explicit host-side diagnostic exception occurs after `BR ready`, while the
unchanged Budget view is active. The profiler retains a failed result with that
reason and hashes its stopped registers/64 MiB memory. This is not a naturally
occurring guest failure. The analyzer finds four live tasks and the bounded
`BudgetEntry → Budget → NativeOriginalView` caller chain; both dynamic function
entries have valid compiled prologues. Four corrupted class/hash/stack cases
are rejected. Internal compiler builtin IDs are excluded from executable symbols.

`build/budget-return-diagnostics-audit-v1/result.json` verifies raw session
exports/key logs, all 1,881 unchanged files, capture provenance and analysis,
1,850 unchanged runtime sources and sixteen unchanged module binaries. Inventory
additions are component receipts; the original failed return remains recorded.

The subsequent [ATA scheduling investigation](i386-ata-poll-scheduling.md)
reproduces a late save inside allocation-bitmap I/O and observes completion
after the 30-second deadline. Bounded worker poll scheduling reduces the measured
Budget saves to 7.0–7.6 seconds in three full cycles; the unchanged normal runner
and cold reopening pass. Historical failures are preserved, and complete
application/release qualification remains open.
