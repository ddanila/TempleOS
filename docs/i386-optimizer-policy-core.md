# Invocation-local optimizer branch policy

CompilerRuntime already contains the complete shared optimizer core. Loading a
second 135 KiB optimizer payload fails in the original-User 8 MiB prototype.
Sharing the resident core instead requires preserving the different allocation
policies of private compiler controls and original public controls.

The shared implementation now exposes OptPass012CorePolicy with two explicit
branch callbacks. The existing OptPass012Core signature remains unchanged and
forwards the containing compiler's original OptBrZero/OptBrNotZero functions.
COptPass012Services and the compiler service table retain their layouts. The
full algorithm is unchanged except for those two dispatches: all opcode cases,
reporting, types, arithmetic and existing CCF_TARGET_I386 branch bypass remain.
Callbacks belong to the invocation; no mutable global allocation policy is
installed across calls or yields. Callers must supply valid live callbacks.

This is a prerequisite for resident reuse. The normal public facade still uses
its complete source implementation. No public controls are passed to private
ownership validators, no namespace/helper publication is bypassed, and no new
resident-core export or public loader has been integrated yet.

## Verification

The candidate under `build/optimizer-policy-core-v1` rebuilds CompilerRuntime
and changes only that module plus the two matching shared sources. Every other
file and boot byte is unchanged. The module grows by 229 bytes, retains its
exact import/service contract and passes the complete 386 instruction audit.
Candidate SHA256:
`caaed5765cd4456bffe4d9165ee8f0cb2fddf35cf36bbb963e10d74432406177`.

- Production User startup/managed pointer at 8 MiB: PASS.
- Public source optimizer at 16 MiB against the pinned original: PASS, exact
  48-word trace, 18 state checks, zero caller heap deltas and fresh arithmetic.
- Native compiler/program diagnostic suite at 16 MiB: PASS through both rounds,
  with exact code-header/emitter boundary and program-completion markers,
  DocAllocationCheck=13 and fresh arithmetic.
- `tools/test-i386-optimizer-policy.py`: PASS. The classic-host fixture executes
  the complete shared core on stack-owned branch graphs over three passes. It
  checks custom zero/nonzero callbacks separately from instrumented default
  callbacks, verifies the existing target-i386 bypass, and exports exact routing
  counters plus a zero heap delta. Its policies intentionally record dispatch;
  they do not test the original branch rewrite algorithm or native public-core
  integration. Earlier exploratory host fixtures failed to compile and are
  excluded; the final fresh run has captured counters and pinned inputs.

Run the focused routing check with a fresh output directory:

```sh
python3 tools/test-i386-optimizer-policy.py --out build/optimizer-policy-new-run
```

`build/optimizer-policy-audit-v1` verifies these receipts and their actual RAM
commands, rehashes inputs, checks exact packaging, and reverses the dispatch
refactor to recover the byte-identical prior algorithm body. That integrity
check supplements runtime evidence; it is not a proof of unexercised branches.
Cross builds and the host test use the retained bootstrap compiler. Two fresh
native generations and the full release/resource suite remain open.

## Capacity evidence and next integration

A separate pre-load probe under `build/optimizer-public-capacity-v1` records
root heap used/reserved = 0xF4518/0xFAC00 and backing used/reserved =
0x112400/0x113000 at 8 MiB. Existing root reservation has 26,344 unused bytes;
the backing pool has 3,072 unused bytes. Neither immediately holds the optimizer
payload. This does not prove that public allocation with growth/reclaim would
fail: other task reservations and reclaim behavior were not tested. The raw
kernel-heap load still fails and no resource gate has been raised.

Next integration must expose the resident policy entry with a validated binding,
supply the complete public branch/diagnostic and helper semantics, and establish
namespace visibility and lifetime. It must pass original User/recovery and
optimizer/API comparisons at the required profiles. This change alone does not
resolve the original-User 8 MiB failure or complete C1–C5.
