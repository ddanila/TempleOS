# Original User loop prototype

The independent live User oracle now passes on a disposable64MiB native image
using the original loop. Production remains unchanged: this candidate fails
8MiB allocation and physical task reclamation. It is not C2/C5 qualification.

The reviewable delta is `docs/patches/i386-original-user-loop-prototype.patch`.
It copies the actual `Kernel/KTask.HC` UserTaskCont body into the child-terminal
path, retaining CmpCtrlNew, Lex, the original shared ExeCmdLine and exception
presentation. The private executor resolves that already loaded system-lifetime
body. The bootstrap remains a control in this experiment; that restriction is
not a final profile policy or a release implementation.

Original GetStr reads through ScanMsg, while the reduced loop consumed XTalk's
private terminal queue directly. The prototype exposes that queue to ScanMsg
for the current task's key-down requests. XTalk publication and consumption also
clear AWAITING_MSG, preserving the scheduler's eligibility rule.

The first candidate stalls after loading the public lexer. A bounded physical
snapshot (`original-user-loop-prototype-v1/debug-task-state.json`) identifies
the child with flags0x200, a complete initializer queued at offset0, and no
prompt marker. The scheduler excludes awaiting-message tasks. That confirmed
failure was stopped and retained; it was not restarted merely for being slow.

Candidate v2 passes cross compilation, complete386 instruction audit and the
unchanged versioned `test-i386-live-user-prompt.py`. All three normalized complete
documents and task states match the pinned original oracle, including directory,
integer/float deferred answers and elapsed fields. Every unrelated packaged file
was independently compared unchanged. Baseline source pins and all three source
overrides remain hashed; the module is explicitly cross-built.

Evidence under `build/original-user-loop-prototype-v2`:

- `completion-audit.json`: partial-prototype, production_ready FALSE.
- Candidate disk SHA256:903cb0d22470370085d61416d9b6233f34bb85df13cd73d3c185271dad11320a.
- ConsoleRuntime SHA256:a546f3a376c235050143834528f98f1c26ae8e6aef96b03eabebccc95e514f02.
- Live oracle receipt:262ae7231056235eb7bf13441d5dc7eb6a2230fc39dfb6e8f79db152994fd77a.
- Patch SHA256:472b6373b8ce7cce5adfaaddbdbb72df5f713e141683bead3a26855cfc190ff1.

## Required gates still fail

The existing User8MiB regression (`build/original-user-loop-user8-v1`) fails
with an80-byte public allocation rejection while loading compiler support.
The public source libraries therefore cannot simply replace the reduced loop
at the existing minimal memory budget. No memory limit or regression was waived.

An extended diagnostic retains the complete prompt oracle, then sends physical
Exit and checks task retirement. The pinned original passes. Native passes the
prompt documents and ends public task validity, but the physical snapshot still
contains its managed task record. Its public compiler-control queue remains
nonempty; the native teardown guards defer reclamation. Ending validity alone
is not storage reclamation.

The corrected diagnostic is under `build/original-user-loop-retirement-v2`.
It serializes pointer bytes into a zeroed I64 using sizeof(child). The v1 wide
lvalue cast had captured adjacent bytes on32-bit; that invalid address check is
excluded. Separate forensic evidence uses the fixed-width TASK REAP address.
The corrected native receipt is
4865756b321f8dc0b5312bdcbafed6df6c315044ae05ada3bb50fa2d11afcada.
Native control/public-control cleanup, interruption and error recovery remain
requirements before integration.

## Resident lexer investigation

To reduce runtime compilation and memory, a separate prototype compiles the
full shared lexer bodies into ConsoleRuntime. No token cases are removed.
The shared dispatch call supplies its null argument explicitly for the existing
C facade declaration. Mutable non-EOL bitmaps resolve to the same kernel objects,
and LexIncludeStr is exported explicitly for the shared parser's dependency.

Earlier variants retain failed compile/debugger/runtime evidence: v3 lacks an
omitted-argument default, v4 reaches the host debugger and observation limit,
and v5 reaches a missing LexIncludeStr dependency. These are not successful
runtime evidence. V6 cross-builds the shared-bitmap variant. V7 cross-builds
with the explicit include export. Its complete386 instruction audit and unchanged
live-prompt oracle pass at 64 MiB. The 8 MiB User regression fails allocating
0x41507 bytes for the original 256 KiB stack plus metadata; the larger resident
module consumes the remaining headroom before that allocation. This variant
therefore does not resolve the minimal resource gate.

The initial public-lexer run produces all 24 exact expected values, then fails
the harness's source-loading instrumentation: it emits one `PUBLIC LEX resident`
marker and no `PUBLIC LEX loaded` marker. The harness now supports an explicit
`--lexer-storage resident` mode, requiring exactly that pair of counts. Its
default still requires one source load and zero resident initializations.
The independent token/ownership bytes and filesystem checks are unchanged.
The fresh resident run passes, including the post-test arithmetic command,
filesystem audit and unchanged-input check:

```sh
python3 tools/test-i386-public-lexer.py \
  build/original-user-loop-prototype-v7/candidate.img \
  --lexer-storage resident --ram-mib 64 --out FRESH_OUTPUT
```

Its receipt is `public-lexer-resident-v1/result.json`, SHA256
748f3eba2332f7ba8b7ba2c66416d9f38c2496c02f514f7febcf24b1ca236b92.
The default-source regression at 64 MiB also passes on the unchanged production
candidate `build/i386-emitter-known-cross-v1/kernel.img`, requiring one source
load and zero resident initializations. Its receipt is
`build/public-lexer-source-mode-regression-v1/result.json`, SHA256
7d2e13a071fcb9c684f7ffca370c1107a76634655d3714c8f3de0b3990974aad.

V7 evidence is under `build/original-user-loop-prototype-v7`:

- Candidate disk SHA256: c3c0e53b7c4eb4eb156fcb047684d6e9bceb806e603a706b9ae4a41ca55b4402.
- ConsoleRuntime SHA256: c90429d6ecf308fd64c4b1de2af7e08ce5a6c11214018bd6182ed80b4fb714b2.
- Live oracle receipt: 5538549ba76d7315c1c82716d4211ea29d697126dcd2be8079d3e08682530c4d.
- `pipeline-result.json` is a terminal observation, not a passing qualification.

The next work must resolve memory, public compiler-control lifetime, interruption
and recovery without replacing the original workflow with formatting-only fixes.
C1-C5 and inventory2/686 remain open; the production60s startup gate remains red.


A later explicit public-control ownership prototype resolves the ordinary Exit
physical-reclamation failure at 64 MiB while retaining the full prompt oracle
and all 24 public lexer checks. It still fails the 8 MiB allocation gate. See
`docs/i386-public-control-ownership.md` and its separate reviewable patch;
production and compatibility qualification remain unchanged.
