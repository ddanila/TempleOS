# Tree and plain-document transformations

These services are dependencies of the complete original DocPutKey dispatcher.
Console 108 shares complete DocCollapse, DocEntryToggle and DocFlagsToggle
bodies with the original system through DocCollapseCore.HC and
DocTransformCore.HC. DocCollapse and DocFlagsToggle are byte-identical
extractions. DocEntryToggle adds one missing Free after printing its temporary
Doc2PlainText result; its remaining branches are unchanged.

## Independent contracts

`tests/guest/i386-doc-transform-reference/Transform.HC` defines eleven cases:

- Three collapse cases use actual tree entries and a non-tree control. Check
  expansion/collapse, unrelated flags/type preservation, default output-document
  selection, incoming lock, caller document/display and exact heap recovery.
- Two whole-document flag cases toggle plain text and plain text with tabs,
  with/without an incoming lock. Check exact literal and structured text, menu
  value 7, no-cursor preservation, the same undo node/ring/count, exact unchanged
  snapshot bytes, caller roles, locks and heap recovery.
- Six entry cases cover formatted-to-literal, literal-to-formatted, whole-plain
  no-op, sentinel no-op, ordinary text without delimiters, and a full entry
  round-trip. Check exact text, menu value, selected document flags, locks, roles
  and exact heap recovery.

Expected literal bytes are constructed independently using numeric dollar,
backslash and quote bytes. The original entry converter escapes quotes in its
literal representation; the reverse conversion removes that quoting. An early
unescaped expectation was rejected by the original, then replaced with this
observed exact format. The whole-document plain representation differs from
that entry representation; each has its own literal expectation.

The first reference run exposed a leak in entry conversion: nine cases passed
and formatted-to-literal returned mask 31 instead of 63. The extended eleven-case
pinned-original control reproduces masks
[63,63,63,63,63,31,63,63,63,63,31], with unchanged inputs, in
`build/i386-c4-transform-leak-control`. Only the heap bits fail in the two
conversions that allocate the unfreed temporary. Freeing it after DocPrint
preserves the text and permits exact recovery on the shared implementation.

Both original bootstrap generations pass. The current-source reference passes
eleven masks of 63 with unchanged inputs in
`build/i386-c4-transform-roundtrip-reference`. The old native Console 107
prerequisite rejects the missing transformation API with unchanged inputs in
`build/i386-c2-transform-prerequisite-red`; the fixture body is not reached.

## Native integration and remaining scope

Three new public document services bring console exports to 265. The native
implementation uses the existing original loader, serializer, navigation,
entry destructor, formatter and recalculation services. Public task/document
layouts, private console services and Memory 26 remain unchanged. There are no
reduced branches or alternate transformation algorithms.

Reproduce with fresh output directories:

```
python3 tools/test-i386-doc-transform-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-doc-transform.py build/i386-c2-transform-cross/kernel.img --out build/NEW-native
```

These bounded cases do not qualify tree child visibility/VGA interaction,
every binary/data-field entry, all wrapping/merge combinations, foreign document
owners, incoming locks for entry conversion, or allocation failure/cancellation/
Exit. Full DocPutKey, chooser, GetStr and TimeClock workflows remain separate
integration gates. The native build/runtime evidence is recorded in PLAN.md;
source sharing alone is not qualification. C1–C5 remain incomplete.


## Final native qualification

`build/i386-c2-transform-cross` passes the limited 386 audit (96 BIOS / 255
protected instructions), and all 1,493 source/build pins match. Native
`build/i386-c2-transform-contract` passes fourteen commands at 64 MiB, exact
fixture readback, eleven expected masks of 63 and unchanged inputs. Current-image
serialization passes 21 commands, clock/undo ten, and normal 8 MiB startup nine
checks in 55.40 seconds with zero build-provider loads. Regression prefixes are
`build/i386-c2-transform-` (save, undo, startup). The limits above remain open;
these results do not close C1–C5 or full input/chooser integration.
