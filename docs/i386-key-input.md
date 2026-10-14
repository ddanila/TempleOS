# ScanKey/GetKey input contract

Faithful GetStr depends on the original keyboard-message and echo path.
`tools/test-i386-key-input-reference.py` captures twenty-eight signed I64 fields
(224 bytes) from the pinned original system and compares them with explicit
host expectations. The producer waits for the receiver's idle/awaiting-message
flags before posting a key, avoiding a sleep-based timing oracle.

| Case | Required observation |
| --- | --- |
| Empty ScanKey | FALSE and both output fields reset to zero |
| Unmatched key-up/mouse messages before a key | Discarded; selected key character/scan code preserved |
| Zero-character key and NULL outputs | A key message still succeeds; NULL output pointers are accepted |
| Queued GetKey with zero character | Returns zero with the nonzero scan code |
| Echo enabled | PutKey hook receives character and scan code once per selected key |
| Descriptor allowed | High scan-code bit preserved and forwarded through the descriptor-enabled hook |
| Descriptor inhibited | Descriptor discarded; next ordinary key returned |
| Delayed GetKey | Producer observes idle/awaiting-message state; receiver wakes and clears idle |

The final pinned run passes in `build/i386-c1-key-input-pinned-final/result.json`.
An initial fixture left its global echo counter uninitialized; explicit zero
initializers correct that test error. Its incorrect count is not an observed
OS input defect.

## Shared source and rebuilt x64 control

`Kernel/KeyScanCore.HC` contains the original ScanKey body verbatim and is now
included by `Kernel/SerialDev/Message.HC`. Extraction preserves the legacy
CP437 bytes elsewhere in Message.HC, including its raw-cursor glyph. No new
input algorithm replaces the original queue, NULL-pointer or echo rules.

The normal two-generation x64 bootstrap passes with the extraction. The same
28-field oracle passes on its generated kernel/compiler and current sources in
`build/i386-c4-key-input-shared-control/result.json`. The runner's
`--current-system` mode checks all source hashes against the passing rebuild
manifest and verifies both overlaid binaries against its final generation.
The report distinguishes this control from the pinned-original baseline.
Physical keyboard decoding, raw cursor blinking, debugger polling, default
DolDoc echo and complete output-hook behavior remain unqualified by this oracle.

## Native shared-core check and remaining public bindings

`tools/test-i386-key-scan-core.py` compiles the actual shared source on i386
under a test-only name. It uses real public task-message queues and a controlled
echo callback, then compares twenty-four captured I64 fields (192 bytes) with
explicit expectations. Queue setup/capture is grouped inside void helpers so
GUI command keystrokes cannot become part of the queue-under-test between
observations. This component test does not supply production KeyDev dispatch
or claim a working public GetKey/GetStr stack.

`tools/test-i386-key-input.py` prepares the full 28-field public-API counterpart,
including real KeyDev registration/echo and a delayed producer. Its first helper
currently rejects the missing ScanKey binding. The later cases do not execute.
Next work must integrate the standard output-hook chain and public ScanKey/
GetKey, including original waiting flags and the platform raw/debug paths,
then connect DocGetKey/GetStr and their prompt, entry replay, filter and task
cleanup behavior. All C1–C5 milestone gates remain open.

The final native component suite passes all twenty-four fields and 21 commands
in `build/i386-c4-key-scan-native-core-final/result.json`, with unchanged input
hashes and exact VGA checkpoints. Its source is bundled by the passing
cross-build/386 audit in `build/i386-c4-key-scan-shared-cross`. The initial native
run had an incorrect FileWrite byte-count assertion; FileWrite returns blocks.
The final check requires positive write completion and independently checks the
exact 192-byte contents, retaining the full semantic oracle.

The current public-API red result is
`build/i386-c4-key-input-public-final-red/result.json`: its helper definition
rejects Invalid lval at ScanKey. The prepared suite contains 28 commands and a
28-field byte oracle, but does not reach its input cases. This is a missing
binding result, not observed failures for every later case.

```sh
python3 tools/test-i386-key-input-reference.py --out build/key-input-original
python3 tools/test-i386-key-input-reference.py --current-system --out build/key-input-x64-control
python3 tools/test-i386-key-scan-core.py IMAGE --out build/key-scan-native
python3 tools/test-i386-key-input.py IMAGE --out build/key-input-native
```

Each command requires a fresh output directory. The current-system control
requires the latest rebuild manifest, matching current source hashes and its
matching generated binaries. Native runs operate on writable image copies;
their source images remain unchanged. They do not establish native release,
startup-memory or background-concurrency qualification.

## Public ScanKey binding checkpoint

[Output-hook dispatch](i386-keydev.md) now provides the native public ScanKey,
PutKey and hook registration/removal path. The 24-field suite's
`--public-bindings` mode passes in
`build/i386-c4-scan-key-public-final/result.json`, using real KeyDev dispatch.
The original alias-mode component test remains available separately. The full
input suite now passes its initial empty ScanKey check and rejects the missing
GetKey in its next helper (`build/i386-c4-keydev-getkey-red/result.json`);
its full 28-field native collection remains unexecuted.

## Public GetKey integration

[Native GetKey](i386-getkey.md) now shares the original wait loop and supplies
native timing/cursor/controller adapters. The full native 28-field collection
passes in `build/i386-c4-getkey-queue-final/result.json`, superseding the missing
binding checkpoint above. Pinned original and rebuilt x64 controls use the same
early consuming echo hook. Physical raw-cursor and interrupt-masked debugger
polling checks also pass; full default document echo and GetStr remain open.
