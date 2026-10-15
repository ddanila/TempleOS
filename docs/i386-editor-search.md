# Original editor search, matching and selection

Console 109 shares the complete StrFind body in Kernel/StrFindCore.HC and five
complete editor bodies in Adam/DolDoc/DocEditorSearchCore.HC: EdFindNext,
EdSelAll, EdFindPaired, EdGoToFun and EdSelFun. Original StrA.HC and DocFind.HC
include the same code. StringFindFlags.HH holds the unchanged boundary/case
flags for both KernelA.HH and native public formatting declarations.

All function bodies are byte-identical extractions. The wrapper edits preserve
all unrelated bytes, including legacy non-UTF-8 text in KernelA.HH. No branches
are trimmed, and no alternate matching/selection algorithm replaces the original.
Native StrFind uses the existing literal matcher, ASCII case-insensitive matcher
and canonical alphanumeric bitmap.

## Paired public contracts

`tests/guest/i386-editor-search-reference/Search.HC` contains sixteen cases:

- String search checks literal offsets, absence, case folding, before/after/both
  label boundaries (including underscore), empty needles, overlap and exact heap.
- Eight find-next cases check forward literal matching, case-insensitive whole
  labels, case-sensitive whole labels, backward matching, absence, selected-only
  text, filtered text and an incoming lock. Expected entry/column are independent
  constants. Input tags and the entire caller search configuration stay unchanged.
- Five pair cases check nested forward/backward matching, absence, double-colon
  abort and a match across three lines. Assert result, exact entry/column, input
  text, incoming lock and caller roles.
- Two function cases check selection of every entry and clearing it, forward and
  backward function navigation, and selection of the current function without
  selecting the following function. One case starts with the document locked.

Document cases require exact caller heap recovery after deletion and preserved
DocPut/DocDisplay. These are direct public-API tests; they do not stand in for
actual editor key routing or visual selection rendering.

The first current-original reference passes sixteen masks of 63 with unchanged
inputs in `build/i386-c4-editor-search-first-reference`. Native Console 108
rejects the missing search prerequisite in `build/i386-c2-editor-search-red`,
with unchanged inputs; its fixture body is not reached. After extraction both
original bootstrap generations pass, and the refreshed current-source reference
passes sixteen masks of 63 with unchanged inputs in
`build/i386-c4-editor-search-qualified-reference`.

Reproduce with fresh output directories:

```
python3 tools/test-i386-editor-search-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-editor-search.py build/i386-c2-editor-search-cross/kernel.img --out build/NEW-native
```

## Integration boundary

Six new public services bring the console export count to 271. The public
format header exposes StrFind and the shared flags; the document header exposes
all five editor services. Public task/document layouts, private console services
and Memory 26 are unchanged. The candidate image contains exact bytes of all
three new source/header files, checked through its RedSea filesystem.

The full remaining DocFind.HC replacement/prompt routines are not yet integrated:
EdFindReplace, EdReplace, the replacement chooser and EdGoToLine need the real
DocForm/class-metadata path and corresponding interaction contracts. These
functions remain intact in the original tree. Full original DocPutKey, actual
chooser, GetStr and TimeClock workflows remain open.

The current cases do not qualify every CP437 case-folding combination, data/bin
fields, every filtered/wrapped selection, empty/malformed documents, foreign
owners, allocation failure, cancellation/Exit or concurrent mutation. Native
build/runtime results are recorded in PLAN.md; source sharing and reference
success alone do not qualify the native implementation. C1–C5 remain incomplete.

## Next replacement/form gate

The remaining replacement and go-to prompts use DocForm. Establish a paired
class-form oracle before porting that wrapper: scalar and string fields,
member format/data metadata, inferred raw types, array lengths/terminators and
explicit/default class names. Exercise real accept/cancel actions and caller
border/document restoration through the original DocEd/DocEntryRun path. Add
failure/lifetime cases rather than substituting a custom prompt handler.

Then integrate the complete DocForm/PopUpForm wrappers and their actual
metadata/type services, followed by complete EdFindReplace/EdReplace and go-to
routines. Require replace/skip/all/cancel, selection and line-filter behavior,
case/whole-label options, persisted document results and cleanup. These remain
future gates; the current read-only search contracts do not prove them.


## Final native qualification and resource observation

`build/i386-c2-editor-search-cross` passes the limited 386 audit (96 BIOS / 255
protected instructions), with all 1,496 source/build pins matching. All three new
files match exact host bytes in the delivered filesystem. Native contracts pass
nineteen commands at 64 MiB, sixteen masks of 63, exact fixture readback and
unchanged inputs. Current-image transformation and clock/undo regressions pass
fourteen and ten commands. Normal 8 MiB startup passes nine checks in 53.89
seconds with zero build-provider loads. Regression prefixes are
`build/i386-c2-editor-search-` (transform, undo, startup).

The 8 MiB debug log contains speculative 8 KiB backing-request failures; the
existing MemoryBacking.HC and Memory.HC policies retry smaller regions/batches.
The required commands and exact VGA checks still pass without a command
rejection. This is observed pressure, not evidence of spare capacity. Measure
mandatory provider footprint before bulk-loading further desktop/tool code;
evaluate the existing lazy-provider boundary without dropping required services
or relaxing the minimal startup/rebuild gates. Full desktop qualification keeps
its separate 64/128 MiB working profiles.
