# Original class forms: metadata and real input oracle

The next full editor dependency is DocForm/PopUpForm in
Adam/DolDoc/DocForm.HC. The original replacement/go-to routines need this
class-driven form path. Native DocForm is not bound yet; this checkpoint adds
executable reference evidence and a native prerequisite test, with no runtime
implementation or completed desktop claim.

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
