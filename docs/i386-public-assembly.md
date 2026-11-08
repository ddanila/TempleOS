# Normal compiler assembly and compilation joins

The normal expression/parser loader currently exposes complete shared statement
and function parsing. Assembly and compilation joins need their own lazy delivery:
loading the opcode table for every arithmetic expression would add avoidable
startup and memory cost. This work is a compiler prerequisite for C1-C5, not
whole compiler, application or native-release qualification.

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
screens remain under `build/i386-public-asm-source-v1` and `-v2`. Normal lazy
assembly delivery, execution/relocation/error ownership tests, current native
regressions and C1-C5 qualification remain in progress.
