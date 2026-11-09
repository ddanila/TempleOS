# Cooperative ATA polling and Budget save latency

A full nested-picker repetition reproduced the reported Budget return timeout in
`build/budget-first-return-stress-native-v1/round-002`. The stopped caller is in
`BgtAcctsWrite → StrFileWrite → DocWrite → FileWrite → I386RedSeaAllocCore`,
reading an allocation-bitmap sector. It has yielded through `I386AtaTaskPoll`
before the first status poll; WinMgr is rendering. The observer has already
retired. This capture does not show a settings-restoration or observer-join wait.

A second diagnostic run snapshots at the deadline and resumes the VM. Its second
save completes at 44.6 seconds, including snapshot overhead; the first took
23.8 seconds. The reproduced failure exceeds the test's 30-second observation
budget and is not a demonstrated deadlock. All captured records remain exact.
The original earlier timeout had no memory capture and remains historical
evidence rather than proof of a particular blocked instruction.

## Scheduling change

The protocol invokes its callback at each wait's beginning and every 64
unsuccessful polls. Previously every worker callback yielded, including ready
PIO phases. Repeated bitmap/directory operations could therefore schedule many
compositor frames during a small save.

Each private ATA channel now retains a last-yield timestamp. Workers admit IRQs
at every callback, mask IRQs to read the 64-bit scheduler clock atomically, and
yield after 16 clock units have elapsed. The public clock uses 1,000 units per
second; checks occur at protocol callback boundaries and the boot timer updates
that clock in coarser steps. This is cooperative admission, not a preemptive
16 ms wall-clock guarantee.

The timestamp is recorded after the scheduled work returns, allowing the pending
transaction to progress after an expensive frame. The token persists across
ready commands and is cleared on channel close. An absent clock retains the
previous callback-by-callback yielding policy. Root polling keeps its existing
IF-clear behavior. Channel ownership, FIFO acquisition, I/O lifetime guards,
status/error checks, poll limits, port ordering and failed-transaction poisoning
are preserved. Only private channel layout changes; public service ABIs stay
Compiler104/Console264/Memory41, with 691 exports and 22 mask words.

## Verification

Both original bootstrap generations pass. The final build is
`build/i386-ata-poll-budget-cross-v2/kernel.img`: 1,850 source and 26 helper pins,
sixteen runtime modules, and the 96 BIOS/332 protected-mode 386 boot audit pass.
Only the three ATA scheduling/channel sources differ from the preceding runtime
build. Only `FileRuntime` changes among module binaries; the kernel and the other
fifteen modules are identical.

`build/ata-poll-budget-contract-v3` adds deterministic callback/scheduler checks
for initial admission, same-clock suppression, the 15/16 boundary, charging work
after yielding, clock discontinuity, absent-clock fallback, token retention
across release/acquire and close/reinitialization. The existing two-drive FIFO,
IRQ ownership, exact ATA command stream, failure poisoning, file-session and
publication/recovery checks still pass, including full 32 MiB disk comparison.
The old unconditional callback with the current layout fails this new probe at
native code 203 (`00:CB`), as expected, in
`build/ata-poll-budget-counterfactual-v1`. Early fixture compiler stops are
retained separately; they are not ATA runtime failures.

Three complete, unchanged-fixture nested-picker cycles pass in
`build/budget-first-return-fixed-native-v1`, retaining the original 30-second
markers and mask 1023. Saves take 7.0–7.6 seconds on this host. The normal runner
also passes mask 1023 and real cold-reopen mask 63 in
`build/budget-entry-picker-io-budget-native-v1`; read-only abort preserves file
bytes, attributes and timestamps. Both returns render fresh arithmetic.
`build/ata-poll-budget-retained-transfer-v1` passes direct/chunked public ATA
reads/writes, guards, counters, preowned locks and filesystem readback.

The small raw-write microbenchmark remains roughly five seconds with WinMgr
active and below a second while paused; it does not show the Budget improvement.
The observed Budget timings are workload evidence, not a general throughput or
release-performance claim. Broader filesystem/rendering overhead remains C5 work.

The audit is `build/ata-poll-budget-audit-v1/result.json`. Historical failed
receipts are preserved. Nested UI/source/record oracles stay unchanged, and
inventory additions remain component receipts. Account-file editing, templates,
other field changes, mouse, resource recovery and complete Budget/C1–C5
qualification remain open; bundled qualification remains 2/686.

```
python3 tools/test-i386.py --ata-tasks --qmp-stdio --out OUT_CONTRACT
python3 tools/test-i386-budget-entry-picker.py build/i386-ata-poll-budget-cross-v2/kernel.img --reference ORIGINAL_PICKER --out OUT_NATIVE
python3 tools/test-i386-retained-ata-transfer.py build/i386-ata-poll-budget-cross-v2/kernel.img --accel kvm --out OUT_TRANSFER
```
