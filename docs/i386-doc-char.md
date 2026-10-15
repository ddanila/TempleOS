# Original character, cursor and form-entry primitives

Console 101 compiles the complete original `Adam/DolDoc/DocChar.HC`, including
EdCurU8, EdCursorLeft/Right, EdLineUp/Down, EdCharIns/Del and EdLineDel. Eight
public bindings expose these primitives. The already compiled original DocTop, DocCenter and DocBottom navigation services
are also exposed. The console export count becomes 246;
public task/document layouts, private console services and Memory 26 are unchanged.

The implementation reuses original entry allocation/deletion, form navigation,
recalculation, data scanning and action dispatch. Original integer rounding uses the existing public math provider through an
explicit RoundI64 import and kernel binding. Printable character bits use the existing original-data bitmap;
BEqu uses the existing native document bit-equivalence helper. DocDollarInputCore
now has an include guard so both input paths share one definition. The original
DocChar function bodies are unchanged, including selection, hex/data fields,
line handling and action dispatch; branches are not replaced with test-specific
logic.

The paired `test-i386-doc-char{,-reference}.py` runners use the same fixture.
Eight text cases check the initial cursor, right/left movement, character
insertion/deletion, line up/down and line deletion. Each requires current
character, the complete first-line text, released document lock, unchanged caller
put document and exact heap recovery after document deletion (mask 31).

Three form cases exercise EdCharIns on actual menu entries: first left/right and
second selection after EdLineDown. They require the selected entry, Escape
handoff, subsequent DocEntryRun result/action, MSG_CMD arguments, unlocked
EdCharIns return with command reset after dispatch, and exact heap recovery
(mask 63). This preserves the original two-stage chooser protocol rather than
inventing a direct-return handler for Space/Enter.

These are component contracts. Native DocPutKey still uses its retained basic
editing implementation. The full original DocPutKey, undo, selection/clipboard,
remaining editor services and actual chooser input must be integrated and
qualified before claiming original form/editor compatibility. Existing native
input behavior is not silently redirected to these primitives. Failure/unwind,
nontrivial selection, hex/data fields and precise peak memory need further
coverage despite their complete source being present.

See PLAN.md for accepted build and test evidence for this checkpoint.

## Evidence

The original two-generation bootstrap and
`build/i386-c2-doc-char-navigation-cross/kernel.img` cross-build pass, including
the limited 386 audit (96 BIOS / 255 protected instructions). All 1482 source and
build hashes match. `build/i386-c4-doc-char-navigation-reference` and
`build/i386-c2-doc-char-navigation-primitives` pass eight masks of 31 followed by
three masks of 63, with unchanged inputs; native checks fourteen commands and
exact fixture readback. Current-image direct-action, restoration and retained-child
Exit suites pass. Normal 8 MiB startup passes nine checks in 52.97 seconds.
The 22-command typed-dollar input suite also passes with unchanged inputs in
`build/i386-c2-doc-char-navigation-dollar-input`.

The first implementation included the integer rounding source inside Console,
which duplicated externally bound math names and was correctly rejected by the
module loader. The accepted image instead imports RoundI64 from the existing
provider. Tests also exposed the missing public DocTop prerequisite, fixed by
exporting the already compiled complete navigation services. Neither fix changes
the original character/cursor algorithm.
