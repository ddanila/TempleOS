# ClassMeta bundled demo workflow

Demo/ClassMeta.HC runs unchanged on the normal native image through ExeFile. Its
SHA-256 remains be318d9ee4d65bf850946b7caf26f4a7461fc965a36e3debb583db7b503948e2,
matching the pinned original inventory entry. The demo defines two classes with
integer, string, F64 and function-pointer metadata, assigns the demonstrated
globals, and calls DumpStruct with its original lastclass default arguments.
No helper/parser/formatter body replaces any part of the application.

Run tools/test-i386-class-meta.py --out OUT on the original, or supply a full
native image before --out. The workflow captures the complete initial DolDoc
output, calls the retained real DumpStruct/RankOut functions after declaration
input release and 32 KiB churn on each allocator, then changes the demonstrated
data and prints it again. Three complete 147-byte documents match the original
exactly, including formatting widths, newlines and the final cursor record.
The initial and retained captures are identical; the changed capture reports
55/Captain and 40/1/1234 while keeping the original metadata defaults.

Mask 511 independently checks the two packed 24-byte classes and member offsets,
all defined initial global values, evaluated integer defaults (including 6/2),
F64 percentile 54.20, string formats, the RankOut function address, missing
metadata, persistence after churn, changed data and unchanged defaults. The
uninitialized color field is not read by the demo (it has no print_str metadata);
its value is not asserted. Its defined color metadata default of RED is checked
by the complete output. Demo declarations and capture buffers intentionally stay
alive until guest shutdown; this is not a delete-all-declarations cleanup test.

Address values are architecture-specific; the callback is checked against each
system's live RankOut entry.

The old normal image fails at the actual MemberMetaData call in the delivered
demo, line 47, before the workflow completes. Console 247 supplies the unchanged
shared lookup functions. Original-v2 and native-v2 then pass mask 511 and all
441 output bytes. Normal arithmetic works afterwards. Independent audits check
all pinned inputs, the unchanged delivered demo, sole fixture volume additions,
unchanged boot bytes and exact original captures.

This workflow is a normal-image C3 check for this self-contained text demo. Its
visual output is checked as exact serialized DolDoc content and formatting;
shared VGA rendering/startup is checked separately by the full welcome-frame
oracle. It does not qualify every member/metadata API, other bundled programs,
physical hardware or the C5 release generations/full-suite/resource gates.

Evidence: build/i386-class-meta-original-v2, build/i386-class-meta-baseline-v2,
build/i386-class-meta-native-v2 and their terminal-integration-audit.json files.

The inventory's qualified status covers this defined complete demo workflow on
the current normal candidate. Its requirement-by-requirement record is
build/i386-class-meta-native-v2/workflow-qualification-audit.json. The inventory
still has 685 unqualified items, and global C1–C5 completion remains unproven.
