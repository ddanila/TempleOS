# Shared PostMsgWait service

ConsoleRuntime 135 exposes original PostMsgWait through `_POST_MSG_WAIT`, appended
at export index 329. Kernel/Job.HC and ConsoleRuntime include the byte-identical
Kernel/PostMsgWaitCore.HC. The native adapter resolves MemoryRuntime's `_POST_MSG`
provider during initialization and forwards all five arguments. The shared body
then calls the existing NativeTaskWait. Provider kind/address validation is
required; the adapter does not invent a second message queue or wait policy.

PostMsgWait means post, then wait for an empty queue and idle recipient. It does
not promise that the recipient has finished all subsequent work. The first
reference fixture incorrectly used Sleep as a processing delay: Sleep sets the
idle bit, so the original correctly returned before the fixture updated its
results. That mask-35 failure and executed fixture remain in
`build/i386-c2-post-msg-wait-reference`. A yielding-recipient control passes
mask 63 in `build/i386-c2-post-msg-wait-reference-yield`; its executed fixture and
runner are preserved. A further original contract adds a separate sleeping
recipient case and passes mask 127 in
`build/i386-c2-post-msg-wait-reference-idle`, with execution inputs unchanged.

The final original control adds the negative MSG_KEY_DOWN_UP pair used by
DocPutKey to stop macro playback, and passes mask 255 in
`build/i386-c2-post-msg-wait-reference-pair`, with unchanged inputs.

The eight cases cover self delivery, default and explicit DONT_FILTER flags,
real worker processing while yielding, an earlier queued message followed by the
waited message, disabled caller interrupts, invalid/null task handling, and
return while the recipient sleeps with an empty queue, plus ordered key-down/up
delivery. They do not qualify
input-filter routing, task death during a wait, or complete DocPutKey behavior.

The preceding ConsoleRuntime 134 image rejects the missing PostMsgWait symbol
in `build/i386-c2-post-msg-wait-native-red`, with unchanged execution inputs. Its
fixture and runner at execution are preserved. Both bootstrap generations pass;
cross-build and the 386 audit pass in `build/i386-c2-post-msg-wait-cross`, with
all 1532 source and 24 build-input hashes unchanged. The native contract passes mask 255 and all three commands in
`build/i386-c2-post-msg-wait-native`, with unchanged execution inputs and exact
VGA checkpoints. This is a 64 MiB functional run with the window manager paused.
The first 8 MiB run records 58.461398-second startup and nine passing checks
with unchanged input hashes, but its isolated timing is invalid: the editor
dialog reference guest started after the coordinator checked for other guests,
overlapping about six seconds. `build/i386-c2-post-msg-wait-startup/isolation-invalid.json`
records the evidence. Preserve this result and perform a fresh isolated run.
The committed-snapshot 16 MiB diagnostics remain running. Future guest launches
must wait until an isolated gate finishes; waiting for a predecessor alone can
race a successor coordinator. C1–C5 and all inventory entries remain unqualified.

```sh
python3 tools/test-i386-post-msg-wait.py --out ORIGINAL
python3 tools/test-i386-post-msg-wait.py IMAGE --out NATIVE
```
