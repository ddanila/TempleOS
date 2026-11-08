# Normal compiler assembly and compilation joins

Normal PrsAsmBlk and CmpJoin now load four complete shared assembly/join stages
on first use, independently of the twelve-stage expression/parser loader. Basic
arithmetic does not load the opcode table. The checked full-content image uses
Compiler 104, Console 263 and Memory 41, with 690 exports and 22 data-mask words.
This is a compiler prerequisite for C1-C5, not whole compiler, application or
native-release qualification.

## Complete shared bodies (2026-11-08)

The assembler expression/listing helpers, compilation join, map writer and
end-of-line skipper now have shared source files. Existing original entry points
include those same complete bodies. The assembler block entry point permits a
host-selected name while retaining its complete implementation. The opcode-table
factory parses the complete opcode source into a returned table; the original
AsmHashLoad wrapper still installs that table, creates its internal types and
attaches it to Adam exactly as before. Argument-type names are shared with the
existing definition-list loader.

Two original-system bootstrap generations pass. The selected thirteen source
hashes and resulting binaries are independently checked by
`build/i386-public-asm-cross-v1/shared-body-audit.json`, whose verifier also
compares the extracted bodies with immutable commit
`bb6c377e5124cf6a99e380ade57b015165e913ee`. This is scoped refactor validation;
the evolving native integration is not accepted by that receipt.

The first source probe rejects the missing LexSkipEol dependency. The second
reaches a missing SwapI64 dependency in the complete operand parser; its
`observed` receipt does not mean successful assembler compilation. Raw logs and
screens remain under `build/i386-public-asm-source-v1` and `-v2`. Those probes
alone establish neither normal delivery nor execution/ownership qualification.

## Normal delivery and precedence investigation

A new normal baseline (`build/i386-public-asm-baseline-v1/result.json`) exercises
PrsFun on an actual function containing assembly. The committed preceding image
raises UndefExt (error counter remains zero), then continues with result 42.
This establishes an execution gap independently of the source-loader probes.

The first integration diagnostic reached all four new assembly stages but failed
when subsequent JIT support parsed U8 as an assembly keyword. Prepending opcode
entries had changed lookup precedence. Appending the complete table fixed that type precedence but left the boot recognition-only
opcodes ahead of real instruction forms. The normal metadata probe observes
MOV with zero forms, while the isolated complete factory returns all 31 expected
forms. Its EAX register record and 64-bit argument mask agree with actual operand
parsing. The final initializer locates the table containing the canonical I64
record, then inserts complete assembly data after those types and before boot
recognition records. It retains the old table if needed and uses the shared
namespace as the AOT lookup root, without alias type copies or pointer
replacement. The failed diagnostic and raw logs remain under `build/i386-public-asm-integration-v1`.

Normal lazy-delivery acceptance passes with
`tools/test-i386-public-assembly.py`. Its 24-field contract rejects eager assembly
loading for basic expression use and checks exact bytes, executable control flow, import
metadata, inline/bare assembly, caller context, canonical types and strict heap
recovery. It injects no compiler bodies or callback replacements. This scoped
contract does not qualify all assembly forms or failure paths.

The first two strict normal contracts (`build/i386-public-asm-contract-v1` and
`-v2`) fail; they are not acceptance receipts. Phase logging identifies successful
data directives and import metadata followed by rejected register instructions.
`build/i386-public-asm-table-probe-v1` records the isolated factory and complete
mask body; `build/i386-public-asm-metadata-v2/guest/assembly-metadata.bin` records
the actual normal-namespace lookup and operand parsing. The earlier metadata
probe fails at a missing forward declaration; its successor locates the real
parser through its function record. These diagnostics add no parser-body or
callback replacement to the normal contract.

## Inline packet and output ownership (2026-11-09)

The corrected table ordering makes every instruction, execution, import, type
and caller-state field pass in `build/i386-public-asm-contract-v3/result.json`.
Its seven inline cases plus raw joins report a 2,376-byte increase in both heap
counters. The public backend had released IR nodes but not the CAOT packet,
code buffer and relocation payloads carried by IC_ASM.

The existing private I386AsmFree body is now shared in AsmReleaseCore.HC and used
by the public backend before releasing its completed graph. It unlinks each
packet and releases its code, relocation names/source links, records and root.
Payload pointers are cleared after consumption. The same cleanup runs after a
backend exception on a valid owned graph; assembly error qualification remains
separate. All eight inline cases, including an unreachable block, execute
correctly in contract-v4, but the aggregate still reports 1,288 bytes.

Caller-side cumulative accounting in `build/i386-public-asm-heap-v2` locates
all 1,288 bytes at the raw forced-I32 short branch. Every later function adds
zero. The retained VGA frame shows the real assembler's expected “could use I8
displacement” warning. This output belongs to the caller's document, so the
aggregate is not solely a parser allocation leak. The initial helper/global
instrumentation variant instead halts with OutMem and is retained as failed
under heap-v1; it contributes no allocation conclusion.

The final fixture retains that exact branch and normal warning. It creates an
owned output document inside the measured operation, verifies and copies the
warning text into preallocated result storage, then releases both the serialized
buffer and document before measuring. There is no heap-counter subtraction,
suppressed warning, shortened case or timing workaround. A separate host check
requires the exported warning bytes. A fresh normal LexExpressionI64 call also
returns 42 after assembly cleanup. With the exact same fixture, the unchanged
pre-release image retains 992 bytes; the final image returns both counters to
zero. Both produce byte-identical warning output. These are direct raw counts,
not a subtraction from either earlier unscoped aggregate.

Run the normal contract:

```sh
python3 tools/test-i386-public-assembly.py IMAGE --out FRESH_OUT
```

Current evidence:

- `build/i386-public-asm-contract-v5/result.json`: 24 fields, eight inline/bare
  cases, an unreachable block, exact data/instruction bytes, executed branches,
  import records, canonical types, caller context, owned warning output, fresh
  expression recovery, zero heap deltas and exactly one publication per service.
- `build/i386-public-asm-release-baseline-v1/result.json`: identical final fixture
  on the unchanged pre-release image, 992 retained bytes and identical warning.
- `build/i386-public-asm-success-v1/result.json` and `-errors-v1/result.json`:
  previous basic/ten extended groups and all 46 error/control rows unchanged.
- `build/i386-public-asm-lex8-v1/result.json`: 24 lexer checks at 8 MiB.
- `build/i386-public-asm-functions-v2/result.json`: 249 audited function cases and
  five deliberate faults on the final original bootstrap.
- `build/rebuild-test/result.json` and `build/i386-public-asm-cross-v4/result.json`:
  two original-system bootstrap generations and full native cross/instruction audit.
- `build/i386-public-asm-welcome8-v1/guest/screen-oracle.json` and the corresponding
  diagnostic16-v1 receipt: full 307,200-pixel TCG486 frames and both diagnostic phases.
- `build/i386-public-asm-cross-v4/final-verification-audit.json`: 1,845 source pins,
  26 build inputs, complete shared-body comparisons, actual delivered bytes,
  bootstrap/modules/images, raw rows, baseline provenance, warning ownership,
  precedence diagnostics and component/profile receipts.

Public assembly error, invalid/unsupported packet, cancellation, allocator/handler
exhaustion and broader function-body ownership qualification remain open, as do
complete assembly-form coverage, Cmp/CmpBuf/file/map workflows and native C5
release generations. Functional 8/16 MiB welcome frames do not qualify startup
performance or assembly at those memory sizes. C1-C5 remain active; bundled
qualification remains 2/686.
