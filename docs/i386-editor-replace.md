# Original editor replacement and navigation contracts

Console 113 now delegates public EdReplace and DocGoToLine to the optional
editor provider. DocEditorReplaceCore.HC shares the complete original
PopUpReplaceSkipAllCancel, EdFindReplace, EdReplace and EdGoToLine bodies.
DocFindPromptTypes.HH shares the actual CEdLineGoTo class/format declaration
with the original system and native root headers. Reconstructing the extracted
source reproduces the original DocFind.HC tail exactly.

The complete existing DocFindCore.HC also moves into the optional provider;
its DocGoToLine, DocFind and DocAnchorFind bodies are unchanged. Public
DocGoToLine keeps its signature and incoming-lock behavior. The latter two
functions' direct public workflows are not qualified by this suite. Prompted
replacement and go-to code is retained and compiled, not replaced with stubs.

## Fourteen independent reference contracts

The shared fixture is tests/guest/i386-editor-replace-reference/Replace.HC.
It calls the original services, not a fixture replacement/navigation algorithm.

| Case | Expected result |
| --- | --- |
| Basic | Replace two occurrences of cat with dog; exact resulting text. |
| Ignore case | Replace both Cat and cat. |
| Whole labels | Replace standalone cat, retaining scatter and cat_. |
| Selection | Replace the selected first line; retain the unselected second line. |
| Empty pattern | Zero replacements; unchanged text. |
| Missing pattern | Zero replacements; unchanged text. |
| Incoming lock | Two replacements; preserve the incoming lock. |
| Oversized pattern | Return -1; unchanged text and settings. |
| Oversized replacement | Return -1; unchanged text and settings. |
| Null replacement document | Return -1; caller document roles and heap unchanged. |
| Line navigation | Go to line 2; exact entry text, y and column zero. |
| Locked line navigation | Go to line 3; retain the incoming lock. |
| Null navigation document | Return FALSE; caller roles and heap unchanged. |
| Prompt metadata | Actual class/member name, I64 type, offset, scalar shape and exact format string, without allocating caller heap. |

Replacement document cases require exact saved CEdFindText bytes after return,
no remaining marker entries, valid signature, exact text/count, preserved
incoming lock and caller output/display/border roles, and exact caller heap
recovery after cleanup. Navigation additionally preserves find settings. Null
cases have no document settings/ring/lock to inspect; those mask bits are
explicitly inapplicable, while return/roles/heap remain checked.

The ten-case original baseline passes in
build/i386-c4-editor-replace-final-reference. The initial native prerequisite
failure in build/i386-c2-editor-replace-prerequisite-red rejected the missing
EdReplace binding before the fixture. Expanded original runs in
build/i386-c4-editor-replace-loader-reference and
build/i386-c4-editor-replace-navigation-reference pass fourteen masks of 63,
with unchanged inputs.

## Native integration and actual memory acceptance

build/i386-c2-editor-replace-navigation-native passes nineteen commands on
486 without an FPU at 64 MiB. Those include all fourteen contracts and cold
EdReplace/DocGoToLine null calls. Null calls do not load the provider. The first
real replacement loads it exactly once, and subsequent calls reuse it. Exact
delivered fixture bytes and pinned inputs are checked.

Private context/services version 4 are 48/52 bytes on i386. The kernel loader
fills the context's six permanent kernel callbacks through its private symbol
index; Console supplies its permanent document-export array. The optional
provider resolves actual split/delete/soft-line/menu/bottom operations there.
There are 276 Console exports; Memory remains 26. No public document/task
layout changes occur. DocGoToLine uses its full shared body inside the provider,
so callback dispatch cannot recurse back through its public loading wrapper.

An earlier build met the span budget but failed normal 8 MiB startup with a
132-byte allocation request while compiling the retained string-returning
function. That failure remains in build/i386-c2-editor-replace-startup. Moving
the complete navigation core out of mandatory Console recovers 5344 bytes
relative to that candidate. Normal 8 MiB startup then passes all nine commands
in 55.55 seconds in build/i386-c2-editor-replace-navigation-startup, with the
editor unloaded. build/i386-editor-replace-navigation-budget.json reports
Console span 2339848 bytes, 5456 below the unchanged cap; other core spans are
unchanged and backing-failure observations are zero. Span is not peak RAM.

The rejected static callback-address array was a cross-builder limitation
(requires folded scalar constants), not evidence of supported target-safe
static-address relocations. Those remain a compiler compatibility gap. Loader
resolution uses the same real kernel functions and avoids that initializer.

Prompted replace/skip/all/cancel, filter lines, local-variable replacement,
exceptions, forced cancellation, popup ownership and concurrent ownership need
additional contracts. Complete original DocPutKey and actual numeric form input
remain required; passing noninteractive replacement is not desktop/input parity.

## Additional final-candidate gates

The nineteen-command search regression and shadowed-first-child ownership pass
in build/i386-c2-editor-replace-search and build/i386-c2-editor-replace-owner.
Version-4 repeated wrong-version rejection, guest repair/retry and cached reuse
pass in build/i386-c2-editor-replace-version-recovery. All inputs remain pinned.

Full 16 MiB no-FPU diagnostic startup passes in
build/i386-c2-editor-replace-diagnostics. Its logs confirm the unchanged 271
public-layout assertions per phase and all 34 zero-delta batches. The host
checker's expected layout count was incorrectly coupled to Console export
count; it now matches DocLayoutCheck.HH and CompilerHeaderProbe.HC. The evidence
report is build/i386-editor-replace-layout-evidence.json. The complete legacy
8 MiB build --test is not claimed. Native component builds remain running;
installed native runtime and full generations remain separate requirements.

## Checkpoint: stronger ownership and pending native audit

build/i386-c2-editor-replace-owner-allocating passes with both _DOC_NEW and
_MALLOC shadowed in the first child. Both shadow identities are checked; the
fixture calls complete DocForm and allocating EdReplace, so the provider's
kernel allocation callback is actually exercised. No poison callback runs.
Two children retire, the second restores the public pool, parent export
identities and caller roles/heap recover, and the one provider image survives
for parent reuse. All inputs remain unchanged.

The final form observation run remains [63,63,63,63,63,60,62] with zero caller
heap deltas in build/i386-c2-editor-replace-form-observation. Those typed cases
are still failures. The current native Console/Editor build job is live in
build/i386-c2-editor-replace-native-build at 16 MiB on 486 without an FPU. Its
export audit and installed runtime are pending. Keep runtime sources frozen
until it terminates; component build intent is not a qualification result.
