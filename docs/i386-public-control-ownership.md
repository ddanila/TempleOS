# Public compiler-control ownership prototype

The original-loop candidate can retire its User task without reclaiming storage:
public CmpCtrlNew allocates a plain CCmpCtrl, while the native compiler drain
validates a larger private control in a different allocator domain. The plain
control left on the task queue prevents physical reaping after Exit.

`docs/patches/i386-original-user-loop-ownership.patch` preserves a disposable
implementation, including the earlier original-loop integration. It is not
applied to production. The public constructor registers successful allocations
in separate ownership records, retaining the original control allocation size
and allocator. Normal CmpCtrlDel performs the shared release and removes the
ownership record. Optional preprocessor hooks preserve the shared source's
behavior when compiled outside the native ConsoleRuntime.

Committed Exit already invokes the storage-owner callback before and after
waiting for descendants. The prototype calls public-control retirement after
render retirement, only when the child list is empty. It counts owned public
controls, preflights bounded reciprocal task-queue links and checks that every
linked public control belongs to that exact queue. It detaches only registered
public nodes, then invokes the existing native drain to validate and release
native controls. Public controls and their ownership records remain allocated
until the native drain succeeds. Their ordinary shared destructor then releases
them before terminal document teardown. Failed validation marks compiler
cleanup failed and retains ownership; it does not fabricate successful reaping.

The first ownership candidate, under `build/original-user-loop-ownership-v1`,
passes the complete prompt oracle and the versioned physical retirement test
at 64 MiB. The latter independently finds no managed child record and locates
the former child address inside a free heap block. All 24 public lexer checks
also pass. This is evidence for ordinary Exit and public lexer ownership, not
complete interruption, exception, corrupt-queue, borrowed-control or resource
qualification.

V2 adds exact queue-membership preflight and optional shared hooks, but uses an
unsupported `continue` statement. Its captured original-host debugger screen
shows the parse failure; no module was exported. V3 rewrites that block using
original HolyC syntax and cross-compiles successfully. All failed and successful
experiments retain their sources, module/patch/source pins and receipts.

Production integration still requires minimal-memory support and broader
lifetime/error/interruption coverage. The existing 8 MiB interactive, 16 MiB
rebuilding and 60-second startup gates remain unchanged. C1-C5 remain open.


The corrected V3 candidate passes all 24 public lexer checks at 64 MiB, including
ordinary shared destructor ownership and the filesystem audit. The unchanged
8 MiB User regression remains FAIL: public compiler-support loading rejects an
80-byte allocation (`PUBLIC ALLOC EXHAUSTED ...0050`). Fixing task reclamation
does not resolve the lazy source compiler's memory requirement.

V3 identities and receipts:

- Patch SHA256: 81e305cdda8575dc4ece4a52818dd6d8a4862ab282494bb50cde4502acb4c58b.
- ConsoleRuntime SHA256: 07a613be2d6862080c220824e16e7843a066ddc410dcacaa1694e0063d84f8f2.
- Candidate disk SHA256: 2c8bfa935004e8f8d307c053edd99211f99c90122c839bc945f55f1e56b6546e.
- `build/public-lexer-ownership-v3/result.json`: PASS, SHA256
  293c6572e148959206311f7980ef0033208477d2f827a3783fd56cf05c1b980d.
- `build/user8-ownership-v3/result.json`: FAIL, SHA256
  1df44dc4134e403437aebee25b9b755a23abc1f69877784a4be09c013aa399d3.

All these runs retain unchanged-input checks. Neither diagnostic success nor a
cross-built module establishes current-source native generation qualification.

The V3 complete prompt/physical retirement run also passes:
`build/original-user-loop-ownership-v3/live-prompt/result.json`, SHA256
a4a821a39449fe7aa73d70dbd6240dcfeb435ba79ef1484e31772affdea9c6b2. All three complete prompt documents
match the pinned original. The native child record is absent, and its former
address lies inside a free heap block. `verification.json` also passes the
complete386 audit, explicit module/four-source replacement audit and baseline
input checks. No unrelated packaged file changes.

Reproduce after cross-building and explicitly packaging the preserved patch:

```sh
python3 tools/test-i386-live-user-prompt.py --retirement --disk CANDIDATE --out FRESH_RETIREMENT
python3 tools/test-i386-public-lexer.py CANDIDATE --ram-mib 64 --out FRESH_LEXER
python3 tools/test-i386-user-startup.py CANDIDATE --managed-pointer --accel kvm --ram-mib 8 --out FRESH_USER8
```


The later corrected `--recovery` oracle also passes on this same candidate:
uncaught throw, compiler error and physical Ctrl+Alt+C during a yielding loop,
then fresh arithmetic and physical Exit reclamation. See
`docs/i386-live-user-recovery.md`. This adds selected error/interruption evidence;
minimal-memory support and broader lifetime/input-pressure qualification remain
open before production integration.
