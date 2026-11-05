# Registry demo first-launch workflow

C1 now has an executable original baseline and a failing native check for the
actual bundled `Demo/RegistryDemo.HC`. Both tests require the demo's exact pinned
source bytes. The test does not replace Game, the clock, RegExe or RegWrite.

The original fixture creates fresh defaults through actual original RegInit,
attaches that writable registry document, and includes the unchanged demo. The
required display is `High Score:1.23000` and `Val:1234`. After execution,
SimpleVal must be 1235; best_score must lie between tS samples taken immediately
before and after the include. The saved registry must contain that increment and
a five-decimal score agreeing with the actual value to its written precision.
The fixture captures the actual output document using DocSave.

```
python3 tools/test-i386-registry-demo-reference.py --out build/FRESH-reference
python3 tools/test-i386-registry-demo.py IMAGE --reference build/FRESH-reference --out build/FRESH-native
```

The native test explicitly packages the unchanged demo on a copy of a normal
seeded image, then launches it through public include/registry interfaces at
64 MiB, KVM 486 without FPU, with live WinMgr. It requires full checkpoint pixel
agreement, time samples, persisted registry state, unchanged demo bytes and an
offline filesystem audit. The source image stays unchanged.

## Observed results and gaps

`build/i386-registry-demo-reference-v2/result.json` passes the first-launch
workflow on the pinned original with the established repair revision. The v1
attempt executed the demo but failed because the capture fixture called the
entry-level Doc2PlainText API with a document only; it is not a passing baseline.
The corrected capture uses DocSave. The original produces the two required demo
lines without intervening scalar-answer output.

`build/i386-registry-demo-native-v1/result.json` is **fail**. The demo include
executes and prints the two expected lines, but additional automatic scalar
answers (0 and 1234) appear before them. Exact display comparison times out.
The expected rows remain original-derived; the test does not accept the extra
lines. Its later time/persistence/filesystem checks have not run and are not
claimed as passing. Inputs remained unchanged.

Read-only source investigation identifies a likely relevant difference:
I386CommandInput invokes its answer callback for each non-void executed output,
while the original ExeCmdLine stores task answer state and CmdLinePmt emits the
answer at a prompt. Included scripts and nested ExeDoc/RegExe execution need a
scoped differential investigation before a runtime fix. This observation does
not establish a complete answer-state or prompt-semantics fix.

The inventory keeps the demo unqualified and links both outcomes. A second
launch, actual reboot/reopen, customized existing state and error cleanup remain
open. This first-launch baseline does not close C3 or any whole registry API.

## Concurrent minimal-profile checks

The complete default TCG gate remains live in
`build/i386-welcome-keyboard-gate-minimal-v1`; it has reached its compiler group.
Its result must be collected before full qualification.

The separate focused compiler run has stopped at command 124 while typing a
repeat of its first command, GetRFlags. Against the valid cursor-on variant,
only fourteen pixels of the prompt differ: the host checker mistakenly treats
the repeated text as the initial black prompt, while the actual later prompt is
green. The source line has not been submitted. Its frozen failure report is
`build/i386-welcome-compiler-v1/failure.json`; completed cases through command
123 do not qualify remaining cases. The oracle's first-prompt identity needs a
fix after the active full run's inputs are no longer pinned.

## Original second launch after document reload

`tools/test-i386-registry-demo-repeat-reference.py` uses the unchanged first
launch fixture, reloads the actual written registry document, and includes the
unchanged bundled demo again on the pinned original OS. It captures a fresh put
document, raw value/time records and the second persisted registry. The first
fixture's completion marker becomes a progress marker so host capture continues;
no demo or registry function is replaced.

`build/i386-registry-demo-repeat-reference-v3/result.json` passes with unchanged
inputs: the second output exactly displays the persisted first score and
`Val:1235`, including DocSave's trailing 0x05, then persists 1236 and a newly
sampled score. The first attempt stopped host capture at the reused first
completion marker; the second captured all records but omitted the trailing
DocSave marker in its host expectation. Neither is a passing reference.

This original workflow proves document reload and repeated launch in one boot,
not an original machine reboot. A native three-boot workflow is being tested
separately: first launch, second launch from the persisted volume after reboot,
then value/score verification after another reboot. Broad registry qualification
remains open.
