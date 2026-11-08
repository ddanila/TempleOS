# Public AOT assembly fixups

Console 254 binds `CmpFixUpAOTAsm` through `Kernel/I386/PublicLoader.HH`.
CMain and the normal system service share the complete routine in
`Compiler/AOTFixupCore.HC`. The existing first-use Adam service now publishes
both JIT and AOT implementations; either entry can trigger the load. The export
table preserves all 672 prior entries and appends the AOT function, for 673
entries. The internal publication context remains a data export at index 671.

The routine performs all eight absolute add/sub fixups and transfers their
records into `cc->aotc`. It resolves grouped local labels, follows forwarding
chains, validates signed relative widths, and transfers remaining imports,
exports and other records to the parent packet in their original order.
The child CAOT and its buffer remain caller-owned. Relative calculations use
scalar I64 addresses before storing through a native pointer, preserving
negative I64 displacements with four-byte pointer storage.

## Record ownership

Successful local-label resolution consumes its import record and source link.
The shared routine also frees its owned name, which `AOTGlblsResolve` creates
with StrNew. The original implementation omitted that free. The reference
fixture measures the original's record/source-link release and then explicitly
releases the retained name; the current shared/native fixture requires the
callee to free all three allocations. Those ownership expectations are explicit,
while relocation and queue results remain the same.

A first local range failure occurs after QueRem: the failed record is detached
from the child and remains caller-owned, with its name, source link, aot pointer
and relative rip unchanged. The tests clean up that record explicitly. Failure
after earlier absolute or import records have been consumed remains unqualified;
the routine retains the original partial-progress policy.

## Contract

`tools/test-i386-aot-fixup.py` packages the native fixture with only the shipping
public-header include. The original mode restores the pinned original routine,
label helpers and public graph helpers under distinct names. Thirty-two
assertions cover:

- Absolute patches at four widths, reversed absolute-list transfer, rebased
  offsets, byte guards and unchanged packet/buffer ownership.
- Retained records of ten relative/immediate kinds, four export kinds and two
  default kinds; parent-prefix preservation, ordering, flags, strings, source
  links, rip adjustment and cleared aot pointers. No symbol is published.
- Grouped and forwarded local labels, use counts, all relative/immediate widths,
  exact record/name/source-link release and missing-label diagnostics.
- Signed 8/16-bit minima/maxima and one-step failures, the 32-bit positive upper
  boundary/overflow and a backward 32-bit patch. The synthetic 32-bit negative
  boundary outside this fixture's representable label-offset domain is not
  qualified.
- Five first-record Compiler exceptions, no patch on failure, detached-record
  ownership, unchanged controller context, repeat empty calls and heap cleanup.

The two raw I64 observations are -24 and -65552 on both architectures. A separate
five-exception LexExcept control measures diagnostic retention: 200 bytes on the
original x64 system and zero on native. The current shared x64 routine matches
that diagnostic baseline after its own complete cleanup. Native retains zero
caller bytes both for the cold service load and after the contract.

The fixture holds the visible document stable during heap snapshots. Earlier
runs observed a 112-byte decrease while yielding to Adam, then the same decrease
in the longer range/cleanup sample once only the cold-load snapshot was locked.
Locking the document for each measured interval makes both deltas exact without
adjusting the cleanup assertions. Unused metric storage is initialized explicitly.
These failed measurement runs remain preserved.

## Verified evidence

The candidate is `build/i386-aot-fixup-cross-v1`. Its final audit checks all
1,774 OS source hashes, 26 build-driver hashes, immutable normal/diagnostic
images and each current report's input pins.

- `build/i386-aot-fixup-original-v4/result.json`: pinned original, all 32 assertions
  and raw negative values, with explicit legacy consumed-name accounting.
- `build/i386-aot-fixup-shared-x64-v3/result.json`: current shared body on original
  x64 scaffolding, all 32 assertions with complete owned-name release.
- `build/i386-aot-fixup-native-v3/result.json`: normal public binding, all 32
  assertions, both raw I64 values, one system publication, exact zero caller heap,
  arithmetic pixels and sole fixture addition to the packaged volume.
- `build/rebuild-test/result.json`, log `build/aot-fixup-bootstrap-v1.log`: two
  x86-64 compiler/kernel rebuild generations using the shared CMain routine.
- `build/i386-aot-fixup-jit-regression-v1/result.json`: existing 40-assertion JIT
  contract, exact trace and heap controls through the same loader.
- `build/i386-aot-fixup-public-source-v1/result.json`: all 25 stages and follow-up
  lexer, graph, expression, type, runtime, lifetime, class, function, statement,
  ExeCmdLine and stream contracts; unchanged inputs.
- `build/i386-aot-fixup-carry-v1/result.json` and
  `build/i386-aot-fixup-class-meta-v1/result.json`: existing integrations.
- `build/i386-aot-fixup-kvm8-v1/result.json`: KVM 486,-fpu startup preflight.
- `build/i386-aot-fixup-welcome8-v1/screen-oracle.json` and
  `build/i386-aot-fixup-diagnostic16-v1/screen-oracle.json`: both complete
  307,200-pixel welcome rasters. The 16 MiB log completes program phases 0 and 1,
  both code-heap ownership transitions and both file-break cleanup cases.

`build/i386-aot-fixup-native-baseline-v1` rejects the previously absent system
symbol before any behavior is exercised. Earlier original and native fixture
iterations remain available, including the unlocked measurement failures.

This component does not establish complete assembler parsing, CmpJoin, AOT file
production/loading, native self-hosting, partial-progress exception cleanup or
first-use failure/retry/concurrency/cancellation qualification. Inventory
qualification remains two of 686 workflows; 684 workflows and the complete
C1-C5 release gates remain open.
