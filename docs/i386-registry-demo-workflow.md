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

## Native persisted reboot workflow

`tools/test-i386-registry-demo-reboot.py` first runs the unchanged first-launch
workflow, preserves its image, and clones that persisted volume for a second
actual QEMU boot. The second unchanged demo launch must display the stored score
and `Val:1235`, then persist 1236 and a newly sampled score. A third actual boot
executes both registry branches, verifies their return values and the stored
five-decimal score, and confirms that verification did not change the saved
fixture/state/time files. Every boot checks exact displayed pixels; volume
integrity is checked after mutation and at completion.

`build/i386-answer-oracles-v1/build/i386-registry-demo-reboot-v2/result.json`
passes with unchanged inputs against runtime commit `82312957`, at 64 MiB KVM
486 without FPU and live WinMgr. The original repeated-launch reference is
`build/i386-registry-demo-repeat-reference-v3`. Original machine reboot is not
covered by that reference; native persistence here is checked against its
original-derived saved values and actual host-extracted volume contents.

The earlier native v1 passed both demo launches but failed the third-boot oracle:
a declaration initializer executed the whole Game1 branch, including nested
SimpleVal, leaving 1236 pending. Its incorrect empty-output expectation is
retained in the failing result with unchanged inputs. The corrected verification
explicitly checks the branch return equals 1236 and then checks the published
score. Customized registries, failure cleanup, complete original UI/API fidelity
and full application qualification remain open.

## Shipped full-content demo and unrelated-file preservation

The drivers now accept an already bundled unchanged demo. `--require-bundled`
rejects an image missing it before launching QEMU; the default minimal-image
fixture path remains available. Existing bundled bytes must exactly match the
pinned original demo. The reboot driver compares all pre-existing source-image
files after the workflow, permitting only the registry and the two explicit test
record files to change (plus the demo addition in fixture mode).

`build/i386-registry-demo-full-reboot-v1/result.json` passes in required-bundled
mode on the combined experimental full-content image
`build/i386-answer-break-oracles-v1/build/i386-answer-picker-full-v1/kernel.img`.
No demo fixture is added. All three actual 64 MiB KVM 486,-fpu/live WinMgr boots
pass the original-derived display, persisted value/score, time bounds and
filesystem checks. The three observed startups are 34.00, 33.99 and 33.89 seconds;
these do not qualify a complete desktop startup budget. Exactly three files
change: `/Registry.HC.Z`, `/DemoRegistryState.HC` and `/DemoTimes.DATA`. The other
1,729 pre-existing source-image files retain bytes, attributes and timestamps.
All input pins remain unchanged.

The same image passes the 1,361-file delivered-source audit and
`build/i386-answer-break-oracles-v1/build/i386-answer-picker-full-content-v1/result.json`:
all 686 inventory files match the candidate workspace (568 remain identical to
the pinned original; 118 are ported/modified), and guest lookup, a 4.3 MB Bible
read and heap recovery pass at 64 MiB. This is content/access evidence, not all
application qualification.

The required-bundled negative case in
`build/i386-registry-demo-require-bundled-red-v1/result.json` rejects the minimal
image with unchanged pins and no guest launch. A default fixture-mode regression
with the stronger file-preservation checks is running separately. The full
C1-C5 requirements and active-branch runtime integration remain open.

The strengthened default fixture path also passes in
`build/i386-registry-demo-fixture-regression-v3/result.json`: all three boots,
source/value/time/filesystem checks and unchanged input pins pass; the other
1,386 pre-existing source-image files are preserved. Only the explicitly added
demo, registry and two record files change. Same-boot re-inclusion of the demo
is not exercised by these reboot workflows and remains an explicit declaration/
redefinition dependency alongside the new CMain publication gap.

## Native second launch in one boot

`tools/test-i386-registry-demo-repeat.py` now executes the original repeated
workflow without rebooting. After the first unchanged include saves its score,
the host reads the acknowledged saved bytes to derive the exact second display
expectation. A public `DocRead` reload replaces the registry document. The second
include must redefine its globals and Game function in the existing namespace,
print the first persisted score and `Val:1235`, then save 1236 and a new score
within its measured execution interval. Test save helpers are also redefined so
their second invocations bind the second launch's globals, rather than old data.

`build/i386-command-policy-registry-warm-v2/result.json` passes all 18 commands
at 64 MiB KVM 486 without FPU with live WinMgr, exact pixels and unchanged input
pins. Its first saved score is 26.34000; the second is 172.00200, both independently
bounded by their recorded tS samples. The minimal source image lacks the demo,
so this run explicitly adds its exact original bytes as a fixture. Only that
addition, Registry.HC.Z and the two test records change; all 1,387 other files
preserve bytes, attributes and timestamps. The filesystem audit passes.

The earlier v1 guest stopped when host screendump writes exhausted disk space;
`host-failure.json` retains its checkpoint and log hashes. It is not a native
compatibility result. The v2 pass closes the measured warm-redefinition gap for
this workflow. A bundled full-image warm pass, customized-state/error cleanup,
whole registry compatibility and C1–C5 qualification remain open.
