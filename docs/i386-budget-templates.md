# Budget interval templates and periodic copies

This C1/C3 component test uses Budget's real `t` and `p` actions, popup forms
and QEMU keyboard input. It starts with no transactions or templates; the
observer never calls an application handler to create or change them.

The workflow is:

1. Type an interval schedule for January 2001, then Shift-Escape cancels.
   Neither a template nor a transaction nor either data/string file may exist.
2. Accept an interval template for September 4–8, 1998, every two days. In its
   second form, enter a 100.00 BANK-to-RENT transaction described as `rent plan`.
   Three generated rows must share the template's strings and owner pointer.
3. Select the first generated row and invoke `p`. Enter September 4–6, every
   day. Change the second form's description to `cash batch`, then cancel it.
   The schedule form must reopen with all accepted schedule values intact.
   Cancel that form too; all three original rows and their ownership survive.
4. Repeat `p` and accept both forms. Periodic copying deliberately skips the
   first occurrence, producing ordinary entries on September 5 and 6. Their
   strings must be independently allocated and their template pointers null.
5. Save Budget, reopen, and abort without writing. Native evidence requires
   shutting down QEMU and booting the saved image without Install or reseeding.

Each filled form has separate exports for its serialized structure, visible
field tags and complete portable backing record. Ordinary data fields commit
on acceptance, not while typing: the draft backing records retain their defaults
or prefilled values. The returned periodic schedule instead contains the values
committed by its earlier acceptance. The observer reads these states without
calling DocDataScan or changing application state.

Live snapshots retain exact dates, types, flags and amount bits, plus entry,
template and string identities. Only two ordinary records and one template are
saved: the three generated rows are reconstructed, not serialized as ordinary
transactions. The independent host oracle checks the complete 156-byte file,
thirteen indexed strings and unchanged 97-byte account file. All expanded dates
have fraction 4 after the original Date2Struct/Struct2Date upward quantization;
the template's stored base transaction retains fraction zero. This calendar
behavior must agree on both targets.

Same-date insertion order is observable. Before saving, the new September 6
periodic row precedes the existing generated row. On reopening, generated rows
are inserted into the already loaded ordinary rows and precede equal dates.
Both report orders and cursor positions are checked explicitly. Cancellation
must retain the original row identities; final copying must preserve all three
original generated entries and their shared strings.

The numerical policy follows [numeric compatibility](i386-lex-number.md) and
[software floating point](i386-f64-backend.md). Original formatted 100.00 parses
to bits `4059000000000001`; native uses exact binary64
`4059000000000000`. Original accepted periods 1.00 and 2.00 have bits
`3FF0000000000001` and `4000000000000001`; native retains their exact binary64
values. Both targets are checked exactly, with no tolerance. Only bytes 32, 64,
116 and 148 of the saved file differ. The retained-schedule and populated-entry
backing records have corresponding exact target-specific checks. Four calendar
ticks are not a target difference.

Mask 262143 covers the observed drafts, both cancellation paths, live template
and periodic results, caller restoration and saved readback. Reopen requires
mask 63, five correct live rows, unchanged saved records and caller restoration.
Native cold reopen/abort must preserve every file's bytes, attributes and
timestamp, and both console returns must render fresh arithmetic 42. This is
not a heap/resource profile.

Use fresh output directories:

```
python3 tools/test-i386-budget-templates.py --archive build/i386-popup-file-editor-cross-v2/exports/BudgetAccts.DD.Z --out OUT_REFERENCE
python3 tools/test-i386-budget-templates.py build/i386-popup-file-editor-cross-v2/kernel.img --reference OUT_REFERENCE --out OUT_NATIVE
```

The source checker still permits only the reviewed Budget sort-slot and three
pointer-width cancellation adaptations. Other recurrence types, template
editing/deletion, mouse interaction, repeated-use resources and complete
Budget/C1–C5 qualification remain open. Component evidence does not qualify the
whole application.

Passing controls are `build/budget-templates-original-v4/result.json` and
`build/budget-templates-native-v1/result.json`, with unchanged inputs.
`build/budget-templates-audit-v1/result.json` rechecks exact raw outputs,
original/native numerical differences, image/source provenance and 112 rejected
corruptions. The reopened native screenshot displays all five reconstructed rows.
No application, compiler or runtime code changed; the image and its sixteen
modules retain all 1,850 source and 26 helper pins. Both existing bootstrap
results still match those inputs; this test/documentation checkpoint needs no
runtime rebuild. Early original fixture-development failures remain preserved
separately and do not count as passing application controls.
