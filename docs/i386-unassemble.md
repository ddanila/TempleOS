# Shared disassembly and raw register support

The original command prompt calls `RawDr` in raw debugger mode. Restoring that
branch requires register presentation, source links and real instruction
decoding. The native startup now loads those helpers and the unchanged
`CmdLinePmt` body in Adam's shared scope through
`Compiler/I386/MakeCommandPrompt.HC`. The retained console still uses its own
input loop; this does not yet restore the public interactive lexer or replace
`NativeTerminalInput`.

`Compiler/UAsmCore.HC` retains the original instruction comparison, lookup,
decoder and `U`/`Un` bodies. The original compiler still builds its tables with
`UAsmHashLoad`. Native code uses the original tables' pointer-free catalog and
retains both the 16/32-bit and 64-bit tables. The native default segment size is
32; the original build keeps 64. Explicit segment-size arguments remain
available. Decoding an instruction does not execute it or require an FPU.

`Kernel/RawRegistersCore.HC` shares the original raw panel body. Native settings
select eight registers, the original `ST_U32_REGS` names, eight hexadecimal
digits, EIP and 32-bit disassembly. The original settings remain sixteen
registers, sixteen digits, RIP and 64-bit disassembly. `PutSrcLink` and the
compiler definition lists also use shared original bodies. The existing kernel
whitespace bitmap is now publicly exported for the unchanged prompt body.
The console scanner imports this same object: exporting a separate bitmap
would leave numeric parsing and string trimming inconsistent with the prompt.

## Opcode catalog provenance and regeneration

`tests/guest/i386-unassemble/Tables.HC` runs on the pinned original system and
exports each already sorted opcode table from reference revision
`c26482bb6ad3f80106d28504ec5db3c6a360732c`. `Compiler/I386/UAsmTables.DATA` is
88,024 bytes with SHA-256
`6949c0939a8eed5376265f0b3dd0c353bc9fa6e7ad69a46d8b44d4311f65b4fc`.
It contains no guest addresses:

- Five little-endian I64 fields: counts 924 and 909, then the original
  64-bit-operand, signed-operand and memory-operand masks.
- Each following 48-byte record contains a 32-byte zero-terminated opcode name
  and the original 16-byte `CInst` record, in table order.

The native loader allocates one `CHashOpcode` owner per record and resets only
`ins_entry_num` to zero, so the original decoder's owner-address calculation
continues to work with native pointer widths. It publishes the table pointers
after allocation and validation, and frees partial allocations on failure.
The catalog is included in both minimal and full disk profiles. The native
installer copies file contents without filtering this extension.

Run `python3 tools/test-i386-unassemble.py --out NEW_DIRECTORY` to regenerate
and compare the catalog against the committed bytes. Original v2 generated it;
original v3 reproduced it exactly. This does not implement the original
`AsmHashLoad` source parser or qualify runtime edits to `OpCodes.DD`.

## Contracts

The disassembly contract calls the actual `Ui` symbol for twelve explicit
32-bit instructions. It checks exact text, consumed lengths, and relative
branch destinations. Branch links must contain the actual exported instruction
address plus the independently specified offset. The original renders `0x90`
as `XCHG U32 EAX,U32 EAX`, and `0x40` as `REX2` even in 32-bit mode; the oracle
preserves these observed spellings rather than silently correcting them.

`tools/test-i386-raw-registers.py` calls the actual `RawDr` with supplied
register values and compiler mode off/on. Independent pixels derived from
`FontStd.HC` check every register and instruction-pointer label/value in the
architecture-specific panel. The instruction row must be blank with compiler
mode off and nonblank with it on. Exact state words check restoration of raw
mode, column, flags and document roles. The dynamic source-address row and
actual decoded instruction text in that panel are not pixel-qualified.

`tools/test-i386-public-file-header.py` includes the public file header twice,
checks that all five tail-function metadata pointers are unchanged, calls
`DirCur`, then checks real arithmetic pixels. The original header ended its
include guard before these five declarations. Re-inclusion rejected publication
without a compiler diagnostic. All declarations now remain inside the guard.

`tools/test-i386-whitespace-bitmap.py` temporarily treats `!` as whitespace.
It checks `Str2I64`, `Str2F64`, `StrUtil` and prompt trimming against the original,
then verifies document roles and exact restoration of all bitmap bytes. Original
v1 passes mask 63; the first native image passes only mask 56 because its string
helpers still use a private copy. Its independent audit confirms the failure
with unchanged inputs and only the fixture added to the volume. The console
module now imports the kernel bitmap instead of defining that copy. Final
`i386-whitespace-bitmap-native-v1` passes all six checks (mask 63).

## Preserved development evidence

- `i386-unassemble-original-v1`: explicitly canceled after the native fixture
  rejected a local nested-array initializer. No original behavior claim.
- `i386-unassemble-original-v2`: twelve lengths/destinations and catalog export
  pass; instruction text was recorded but not yet asserted by that runner.
- `i386-unassemble-original-v3`: exact text, lengths, destinations and catalog
  reproduction pass with the final fixture and oracle.
- `i386-unassemble-native-baseline-v2`: public `Ui` is absent before behavior.
- `i386-unassemble-candidate-v3`: diagnostic source-loaded decoder matches the
  original instruction text and state after restoring register dictionaries.
  It is not normal-boot qualification.
- `i386-raw-registers-original-v1`: fixture state passes; the first host oracle
  used single-line border glyph 0xB3 instead of original double-line 0xBA.
- `i386-raw-registers-original-v2`: corrected original panel/state checks pass.
- `i386-raw-registers-rebuilt64-v1`: the refactored two-generation x86-64
  bootstrap passes the same panel/state checks.
- `i386-public-file-header-baseline-v1` and the staged library trace reproduce
  failure when the old public file header is included again.

The first cross image omitted the catalog from its volume and failed startup.
A corrected package then exposed the repeated-header failure. These images
remain unqualified; seeing `DONE native kernel startup` after a source error is
not proof of successful startup. Cross-v2 was a failed host repack attempt on a
nonzero old filesystem and was never booted. Cross-v3 has a verified fresh
filesystem but still contains the old header guard. Cross-v4 is a fresh build
with both corrections. Cross-v5 exposed the host import audit needing the
new shared bitmap import; the corrected audit accepts it and rejects a mutated
name. Cross-v6 is the final fresh build, including the shared bitmap.

All paths above are under `build/`. No inventory item is fully qualified by
these contracts. Complete opcode/operand coverage, source-link and `U`/`Un`
workflows, debugger entry/resume/step/unwind, public interactive lexing,
physical prompt input, exact failure-path resource recovery and C5 installed
native generations remain open.

## Final verified image

`build/i386-command-prompt-cross-v6/kernel.img` has SHA-256
`9532b366565269fcff91725962b459d7d9522108a96433a25e9ad57ac63aa909`.
The full cross-build and two-generation bootstrap pass; all 1,746 production
source hashes match the working sources. The kernel is 419,896 bytes. Public
console service version remains 234; its private loader bindings increase to
65 to import the existing kernel whitespace object.

The following normal-boot 64 MiB contracts pass on this image:

| Evidence directory under `build/` | Observed contract |
| --- | --- |
| `i386-command-prompt-native-v4` | Six original prompt cases and exact 24-word state |
| `i386-unassemble-native-v4` | Twelve exact instruction texts, lengths and destinations |
| `i386-raw-registers-native-v4` | Nine native register/EIP rows and both compiler-mode states |
| `i386-whitespace-bitmap-native-v1` | All six mutation/restoration checks, mask 63 |
| `i386-public-file-header-native-v2` | Repeated public header publication, mask 63 |
| `i386-terminal-handoff-prompt-v2` | Retained child handoff, masks 31 and 63 |

Each directory contains `result.json` and `terminal-audit.json`. The independent
audit rechecks every execution input, unchanged boot bytes, original file tuples,
the sole frozen fixture addition, filesystem allocation and successful startup
without source errors or rejected input. `final-contract-audit.json` in the
cross-build directory also compares exported prompt, decoder, raw-register and
bitmap states against the original and checks exact catalog reproduction.

The same build passes normal 8 MiB startup and 16 MiB diagnostics: both compare
all 307,200 welcome pixels exactly, and diagnostics complete both program,
code-heap ownership and file-break cleanup phases. These concurrent runs do not
establish the isolated 60-second startup budget. Minimal-profile packaging is
separately verified in `i386-command-prompt-minimal-package-v2`; that result
checks the catalog and volume, not a minimal-image boot.

## JIT trace pointer widths and decoder compilation

The normal JIT trace now exercises formatted Un output, including DolDoc
highlight commands. Ui computes padding with scalar address differences rather
than reinterpreting a stored four-byte pointer as I64; Un forms its byte end
pointer without that reinterpretation. The complete ModRM/SIB block is extracted
unchanged into UAsmModRM, preserving its arguments and prefix state while reducing
the largest compilation graph. Original Ui, the current decoder on original x64,
and normal native Ui pass the twelve exact cases; the full native JIT trace also
matches the original's complete 113 bytes. Both full 8/16 MiB welcome rasters pass
with the extracted decoder. See docs/i386-jit-fixup.md for evidence and remaining
opcode, compiler, unwind and lifecycle limits.

## Fixed native catalog capacity

The native-only catalog initializer now uses the retained exact-page allocation
provider for both lookup arrays and all opcode records. Its complete pointer-free
catalog remains unchanged: 924 16/32-bit entries and 909 64-bit entries. A captured
normal allocation had 263132 bytes of capacity for 131976 bytes of opcode data.
The fixed allocation has 132060-byte capacity, removing 131072 excess bytes.

`build/i386-ir-slabs-unassemble-capacity-v6/result.json` checks this at 8 MiB,
alongside the unchanged twelve original Ui cases. Public MSize requested/capacity
pairs are 3696/4060, 3636/4060 and 131976/132060; each buffer covers its data with
less than one native page of spare capacity. Captured catalog validation checks
every one of the 1833 names and instruction encodings. Complete opcode execution,
U/Un, symbol-link and general register workflows remain unqualified.
