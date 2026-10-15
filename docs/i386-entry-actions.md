# Original document actions and chooser service integration

Console 100 compiles the complete original DocEntryRunCore and DocMenuCore with
the complete PopUpMenu and PopUpPickLst bodies. The latter two are extracted
unchanged into DocMenuPopupCore.HC and DocPickLstCore.HC, shared with the original
system. Native binding maps PopUp, PopUpPrint and WinToTop to their existing
providers. Explicit forward declarations resolve the action/list/menu cycle;
there are no replacement branch implementations or unsupported-action stubs.

Public bindings add DocEntryRun, DocMenu, PopUpMenu and PopUpPickLst. The console
export count becomes 235; its private service table and public task/document
layouts do not change. Memory remains version 26.

The new `tools/test-i386-doc-entry-action-state.py` and paired reference runner
use `tests/guest/i386-doc-entry-actions-reference/DocEntryActions.HC`. Eight
cases cover left/right expressions, left/right unlocked callbacks, no action,
collapse, Escape and Quit. Mask 63 checks result, action indication/toggle,
message type/arguments, lock state and callback unlock, command reset and exact
caller-heap recovery. Both cases of callback dispatch must execute with the
document unlocked. The native fixture is additively staged on a writable copy,
then read back exactly, with its tools and input image pinned.

The existing `test-i386-doc-entry-actions.py` and its independent dollar-parser
fixture are preserved. The actual chooser runner now also uses additive staging
instead of typed source transfer; its five chooser cases, callback observation,
message and state checks remain intact. This reduces upload overhead without
changing the required chooser behavior.

Full action compilation is not full chooser qualification. The complete original
DocPutKey/editor primitive path, macros/links/define-list actions, popup child
presentation and ownership, failure/Exit/recovery and real input workflows still
need their own contracts. In particular the retained native DocPutKey implements
only basic editing and dollar input; it must not be treated as a complete form
input implementation. See PLAN.md for final run results for this checkpoint.

## Qualification evidence

`build/i386-c2-menu-actions-provider-cross/kernel.img` passes cross-build and the
limited 386 audit (96 BIOS / 255 protected instructions), with all 1482 source
and build hashes matching. The original two-generation bootstrap passes.
`build/i386-c4-entry-actions-provider-reference` and
`build/i386-c2-menu-actions-action-state` pass all eight masks of 63; native
fixture readback and input pins pass. Current-image restoration and retained-child
Exit regressions pass. Normal 8 MiB startup passes nine checks in 50.45 seconds.

The original full chooser returns [11,12,22,-1,17,1] in
`build/i386-c4-menu-actions-chooser-reference`, with unchanged inputs. Native
`build/i386-c2-menu-actions-chooser-input` compiles the same fixture after
explicitly loading its ScanCodes.HH prerequisite, then enters `MCChoose(0)` and
reports `MENU begin` without completing the selection. This remains a failing
acceptance gate; direct-action success does not qualify keyboard form selection.
The native chooser runner pins ScanCodes.HH as well as its fixture and packaging
tools. Continue by integrating the full original DocPutKey and editor primitives,
rather than translating only this fixture's Space/Enter keys into actions.
