# Original class forms: metadata and real input oracle

The next full editor dependency is DocForm/PopUpForm in
Adam/DolDoc/DocForm.HC. The original replacement/go-to routines need this
class-driven form path. Console 111 now has a native integration candidate behind the optional editor
provider. Its typed-input acceptance remains failed; the original oracle and
previous prerequisite failure below remain reference evidence.

## Seven original cases

The same guest fixture is used by both runners:
`tests/guest/i386-class-form-reference/Form.HC`.

| Case | Expected original behavior |
| --- | --- |
| Unknown class | FALSE, without entering a form. |
| Class without format metadata | FALSE, without entering a form. |
| Explicit mixed class | Escape accepts; scalar, fixed string, checkbox and allocated-string fields have the expected bindings; header/footer are present. |
| Inferred mixed class | `lastclass` chooses the actual argument class; Escape accepts the same bindings. |
| Sized mixed class | Shift-Escape cancels; the sized-down window remains, following original DocForm ordering. |
| Numeric edit/accept | Real queued keys 4, 2, Escape change an I64 field from 12 to 42. |
| Numeric edit/cancel | Real queued keys 4, 2, Shift-Escape leave that field at 12 with this non-UPDATE_DATA format. |

A public key-device hook observes the live form, returns FALSE and neither
consumes keys nor modifies the document. It checks actual data addresses,
I32/I64 scalar inference, the fixed string's inferred length 7 and pointer
carrier type, checkbox raw type, and REMALLOC_DATA's data/owner-field linkage.
The mixed structure has unformatted guard fields around fields whose layouts
differ between 32-bit and 64-bit targets. Final values, guard preservation,
key-hook ring restoration, document/border/end-callback roles, title/attributes,
window behavior and exact caller heap recovery are asserted.

The hook uses positive priority 1. An initial negative priority circled past the
original key-hook ring's zero-priority sentinel and was terminated after source
inspection identified the loop. This was a fixture error, not a form result.

## Original details that the oracle preserves

An initial assumption that a string field's raw type was RT_U8 was wrong:
DA-P uses RT_PTR as its value carrier, with the array element type used to infer
length. Bool uses RT_I8. These observations are explicit metadata expectations.

DocForm sets SIZE_MIN and recalculates before DocEd saves its window bounds.
Consequently the original direct sized form retains its smaller bounds after
return. The oracle checks those bounds against the observed live form and
requires shrinking; other cases require unchanged bounds. Only after recording
that result does fixture cleanup restore the window for subsequent cases.
This is not a claim that every form cancellation rolls back every field.

The initial root-heap-zero assertion was also unsuitable for this observation:
interactive cases change the shared Adam heap, and yield-only Refresh/Yield
controls have positive and negative deltas without a form. The final assertion
requires exact caller heap recovery. Root deltas and yield-control deltas remain
raw telemetry; they neither prove a per-call leak nor qualify root ownership
cleanup. Key-hook topology and caller state remain strict checks. Targeted
ownership/lifetime tests are still required for native integration.

## Evidence and commands

Both `build/i386-c4-class-form-final-reference` and
`build/i386-c4-class-form-repeat-reference` pass seven masks of 63, with all
caller heap deltas zero and unchanged inputs. The reports retain binding masks,
observation counts, string type/length, window comparisons and root/control
heap telemetry. They run on the qualified current x64 rebuild.

`build/i386-c2-class-form-prerequisite-red` passes native lastclass inference,
then rejects the DocForm binding (Invalid lval). The actual form fixture is not
reached, and inputs stay unchanged. Native UI/editing is not qualified.

```
python3 tools/test-i386-class-form-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-class-form.py build/i386-c2-editor-search-cross/kernel.img --out build/NEW-native
```

Next integrate the complete original wrappers and real metadata/type services
through the editor-provider boundary, then run the same form cases. Do not
substitute direct field writes or a custom prompt handler for the queued input.
Add custom data metadata, more arrays/scalars, popup ownership, action callbacks,
allocation failures and cancellation/Exit tests before broad qualification.
C1–C5 remain incomplete.

## Complete wrapper integration candidate

DocClassFormCore.HC and DocFormPopupCore.HC contain the exact original DocForm
and PopUpForm bodies. Compiler/OptClassFwdCore.HC similarly shares the complete
class-forwarding helper with the original compiler. Exact extraction comparisons
pass, the original compiler/kernel rebuild themselves twice, and all seven
original form masks remain 63 in
`build/i386-c4-class-form-shared-reference`, with zero caller heap deltas and
unchanged inputs.

The optional provider includes full MemberLookup.HC and the forwarding helper;
its private version-2 context borrows stable Console callbacks for allocation,
metadata lookup, document creation/output, data formatting, editing, actions
and popup execution. DocPrint/PopUpPrint borrow the real variadic Console function pointers,
preserving their calling convention. No custom prompt or direct replacement field-write path is
introduced. Context/services are 84/44 bytes on i386. Public DocForm/PopUpForm
entries preserve lastclass defaults and raise the Console export count to 273;
Console is version 111, Memory remains 26.

Initial cross-builds exposed an intrinsic-address error, missing private
service fields and the missing raw-type header. LBtr now uses the intrinsic
already supplied by Intrinsic.HH; no callback or original-body change is needed.
The first compiled Console span exceeded the new budget by 392 bytes. Borrowing
variadic functions directly removes unnecessary resident adapters.
The corrected cross-build passes in
`build/i386-c2-class-form-variadic-cross`: 569584 native kernel bytes,
1502 matching source/build pins and the limited 96-BIOS/255-protected-mode
boot audit. The extracted Console span is 2345016 bytes, 288 below the budget;
normal-boot and native form results are recorded below.
A fresh original run on the final source snapshot also passes seven masks of
63 with zero caller heap deltas and unchanged inputs in
`build/i386-c4-class-form-variadic-reference`.
Full original input behavior, popup ownership, cancellation and failure cleanup
remain required even if the first form cases pass.

## First native runtime findings

Normal 8 MiB startup passes nine commands in 57.69 seconds with no editor load
in `build/i386-c2-class-form-startup`. The qualified footprint report
`build/i386-class-form-provider-budget.json` passes at 2345016 Console bytes
(288-byte margin), unchanged other core spans and zero backing-failure
observations. The search suite and version-2 wrong-version repair/retry pass
in `build/i386-c2-class-form-search` and
`build/i386-c2-class-form-provider-version-recovery`.

The initial strict form run stopped at case 3 (inferred class), without detailed
mask telemetry. The later observation run passes cases 0–4 and 6 and records
case 5 as mask 61. A strict repeat with failure telemetry passes cases 0–4,
then logs `FORM FAILURE 5 61 1 31 12 0`: binding correct, expected accept/value
checks correct except the numeric field remains 12, exact caller heap recovery.
The initial case-3 failure remains unexplained; no reliability claim follows
from its later passes.

This also exposes a weakness in the old cancel case: leaving the field at 12
could pass even if typing did nothing. Both numeric cases now require the
observing key hook to see the live tag N:42 immediately before Escape. The hook
still returns FALSE and never writes a field/document. The strengthened
original oracle passes seven masks of 63 with zero caller heap deltas and
unchanged inputs in `build/i386-c4-class-form-typed-tag-reference`.

The native runner has a separate --observe mode, marked observed/diagnostic-only,
which logs masks, binding/observation counts, caller heap, final numeric value
and whether the live tag reached 42. It does not replace the strict assertions
or establish compatibility. The strengthened strict native run in
`build/i386-c2-class-form-typed-tag-native` passes cases 0–4, then fails numeric
accept with mask 60, binding mask 1, value mask 31, final numeric 12 and heap
delta zero. The diagnostic-only run
`build/i386-c2-class-form-typed-tag-observation` records
[63,63,63,63,63,60,62], final numeric 12 throughout, and no edited tag in either
numeric case. All caller heap deltas are zero and inputs remain unchanged.
Cancellation now fails correctly when typing never edited the field. Full PopUpForm workflow and original DocPutKey integration remain open.
