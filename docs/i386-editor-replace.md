# Original editor replacement contracts

Full original document input depends on EdFindReplace, EdReplace and the
prompted go-to/replacement services in Adam/DolDoc/DocFind.HC. Read-only
search/selection and complete form wrappers do not implement those services.
The current native EdReplace entry is unavailable; the paired test stops at
its binding check before reaching the guest fixture.

The shared fixture is tests/guest/i386-editor-replace-reference/Replace.HC.
It calls the original public EdReplace, not a fixture replacement algorithm.

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
| Null document | Return -1; caller document roles and heap unchanged. |

Document cases require exact saved CEdFindText bytes after return, no remaining
marker entries, valid signature, exact text/count, preserved incoming lock and
caller output/display/border roles, and exact caller heap recovery after
cleanup. The null case has no document settings/ring/lock to inspect; those
mask bits are explicitly inapplicable, while return/roles/heap remain checked.

The initial original execution produced ten masks of 63, but the host wrapper
looked for the preceding search oracle's artifact filename. The corrected
runner reads editor-replace.bin and passes all ten masks with unchanged inputs
in build/i386-c4-editor-replace-corrected-reference. After making the null-role assertion explicit,
`build/i386-c4-editor-replace-final-reference` also passes ten masks of 63
with unchanged inputs.

build/i386-c2-editor-replace-prerequisite-red rejects the missing native
EdReplace binding before the fixture runs, with unchanged inputs. This is a
prerequisite failure, not a replacement-behavior failure. The suite covers
EdReplace's noninteractive path; prompted replace/skip/all/cancel, filter lines,
local-variable replacement, exceptions, cancellation and concurrent ownership
need additional contracts.

Next share the complete original replacement/go-to bodies at the optional
provider boundary, supply their real dependencies and run the same fixture.
Retain all prompted branches and full input/tool shortcuts. Do not implement
a separate plain-text replacement loop merely to satisfy these cases.
