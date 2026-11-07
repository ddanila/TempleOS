# Public single-table hash lookup

Normal native startup now exposes HashSingleTableFind with the original signature
and default instance=1. Kernel export slot 95 binds the existing native function;
the export count is 96. Existing slots, compiler runtime 85 and console 245 are
unchanged. The lookup stays within one table, unlike HashFind, which follows
borrowed parents. Matching entries increment their U32 use count; instance
selection and masks use the full I64 arguments.

Run tools/test-i386-hash-single-table.py --out OUT for the original system, or
supply a native image before --out. Original-v1 and native-v1 both pass mask 1023:
misses, default and second instances, type filtering, parent exclusion versus
HashFind, zero/negative/large instances, a zero mask, exact use counts, U32 wrap
without adjacent-field corruption, and exact data-heap recovery. All entries
collide in a single bucket. The old normal image rejects the first call at line
17 (baseline-v1), before exercising the API.

Independent terminal audits verify current input hashes, exact fixtures,
fixture-only native volume mutations and unchanged boot bytes. Both x86-64
bootstrap generations rebuild and boot; the full native build passes all 1758
source pins and the 386 instruction audit. These bootstraps do not establish
binary identity or C5 native-generation qualification.

Both 8/16 MiB normal profiles match all 307200 welcome pixels. The diagnostic
profile also completes both program, code-ownership and file-cleanup phases.

The binding removes the missing dependency exposed while source-loading actual
class/function-header compiler bodies. Their execution and cleanup, normal
public compiler delivery, concurrent lookup/mutation, invalid metadata and full
C1–C5 qualification remain open.

Evidence: build/i386-hash-single-table-{original,baseline,native}-v1,
build/i386-hash-single-table-cross-v1/terminal-source-and-contract-audit.json,
and build/rebuild-test/result.json.
