# Keyboard input under document-save pressure

The native keyboard actor previously decoded at most one event before yielding.
A concurrent document save can make a scheduler turn much longer than a key
interval. The 64-byte raw ring can then fill before the worker drains it. Loss recovery discards ambiguous pending input, which can
leave an incomplete command in the terminal document.

The retained pressure reproducer continuously calls DocSave on the child input
document while physical keyboard input exercises the complete original prompt,
uncaught throw, undefined identifier and a yielding-loop Ctrl+Alt+C. The pinned
original passes. The unbatched native ownership image fails before entering the
loop. Its saved document contains:

```text
U0 RecoveryStU8(0xE9,83E)Yield;}RecoverySpin;
```

The host sent the complete function definition, including all three OutU8 calls.
A stopped physical snapshot independently records six raw-ring dropped bytes and
two decoded/post-loss resets. This establishes an input delivery failure before
the parser, rather than an unsupported function definition.

`NativeKeyboardWorker` now drains a bounded batch of up to 64 decoded events
before each scheduler yield. Each existing pump invocation retains its own IRQ
restoration, FIFO order, arrival timestamp and loss handling. The actor still
yields under continuous input. Raw queue size, public interfaces and actor stack
size are unchanged.

The diagnostic original/batched pressure runs pass all prompt, recovery and
physical reclamation checks. A separate production-source candidate contains
only this keyboard worker change; its unchanged 8 MiB managed-pointer User test
passes. The original-loop/ownership implementation remains a separate prototype;
its minimal-memory failure is not resolved by this scheduling change.

## Versioned regression

`--document-pressure` implies recovery and retirement, selecting the separately
pinned `PressureObserver.HC` fixture. It retains the exact initial prompt oracle
and all recovery checks, including the full function echo. Native additionally
requires zero raw-ring drops and zero decoded/post losses, decoded from stopped
physical memory using the loaded kernel/console module symbol tables. Failure
snapshots retain both counter sets. Zero software counters alone cannot exclude
controller loss; command/document and state checks remain required.

```sh
python3 tools/test-i386-live-user-prompt.py --document-pressure --out FRESH_REFERENCE
python3 tools/test-i386-live-user-prompt.py --document-pressure --disk IMAGE --out FRESH_NATIVE
```

The baseline diagnostic artifacts are under `build/live-user-input-pressure-v1`.
The input-batched original-loop candidate is under
`build/original-user-loop-input-batch-v1`; the production-only candidate is under
`build/keyboard-batch-production-v1`. Their cross-build and complete386 audits
retain source/module/patch hashes, explicit packaged source replacement checks
and unchanged unrelated files. The production driver's inherited cross-build
scope text still says original loop; its actual overlay has an unchanged
ConsoleRuntime source and only the keyboard delta. The verification receipt
states the production scope correctly.

These are selected functional checks. Existing minimal startup/resource gates,
full concurrent desktop behavior, complete API/application inventory and two
current native generations remain separate C1-C5 requirements.


## Current evidence

The versioned pressure regression reproduces the old failure: two raw bytes are
dropped and two decoded loss resets occur. The batched image passes the same
full input/recovery/reclamation workload with both counters zero. An independent
audit reconstructs the host's submitted lines from raw key-down/shift events:
the complete loop definition was sent exactly once in original, unbatched and
batched runs. Its absence from the failed native document is therefore not a
truncated host command.

- `build/live-user-pressure-reference-v1/result.json`: PASS, SHA256
  ea9cefa4b7294b49afef025487891263f482beeedd8454e0f7c1896ec3dd22f5.
- `build/live-user-pressure-unbatched-v1/result.json`: expected FAIL, SHA256
  03fe32384d15b2c5cffa4c357ab09653bd4db39f75eecbba9ead625112a6fb54.
- `build/live-user-pressure-batched-v1/result.json`: PASS, SHA256
  77c0f489a2129700b82894c49eb13731a57f3a35a3c39f230fe78cdf1e851f4c.
- `build/keyboard-batch-production-v1/user8/result.json`: PASS, SHA256
  9c3a9b7a4d5d3496bb64bbc9a31c9b5f20c70b1fed06b92d87106edf8e5da8a0.
- `build/keyboard-batch-production-v1/desktop-home-once/result.json`: PASS,
  SHA256 b5818b519d5a7b71b8ea9677881a253f7c6308a5586c5cdf174d92d26f8b6422.
  This includes Home Once selection, original geometry, fresh42 and independent
  bootstrap record/free-block reclamation.
- `build/keyboard-batch-audit-v1/result.json`: PASS, SHA256
  8f26ffd7170fcf5e606cd03dc18c404c42c50b2e546c986c0934f92d13c64328.

The production ConsoleRuntime grows by 136 bytes to 2,462,801 bytes, SHA256
3cca73219dd9826c81059be1481b7108023b511352f0f5977b14fda31ff35179.
Its candidate disk SHA256 is
256fa4e4722748d1ecfb647cb0b8df7238876bac9f746e8ae969538bf29b1424.
The full original-loop candidate disk SHA256 is
320e8d69cee001864047101fb102d0b053feba3d01eec48659f896a2817c0838.
Both instruction/packaging audits pass. The source audit verifies that only
KeyboardMessages differs from the production native-source baseline, and that
its bytes exactly match both tested overlays. The earlier ownership patch still
applies on main; compiling it now includes this keyboard change, so its older
unbatched module hashes remain historical identities.

The selected continuous-DocSave input-loss case is fixed. Other input rates,
workloads, controller behavior and complete concurrent desktop workflows remain
separate qualification work. No startup threshold, memory profile or inventory
status was relaxed.
