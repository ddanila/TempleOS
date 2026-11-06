# Native HolyC inline assembly

The i386 function backend accepts `IC_ASM` blocks and instruction statements.
The shared HolyC assembler emits the bytes on the compiler host. Native blocks
default to USE32; explicit USE32 is allowed. USE16, USE64, 64-bit general
registers and extended general registers are rejected on this target. The x64
assembler's mode selection remains unchanged.

`Compiler/I386/Asm.HC` appends assembly bytes to the native function output.
Relative I8/I16/I32 references to enclosing HolyC/assembly labels are fixed up
using native byte offsets on the final emission pass, including numeric addends.
Resolved assembly-local branches are already position independent. Branches into
assembly use the label's offset within the block. The nested native parser keeps
assembly label nodes, appends them to the enclosing function and joins preceding
HolyC goto placeholders to their definitions before assigning addresses.

Assembler expressions are a separate host operation. They may read the live
I64 value fields of unresolved host assembler symbols, so they cannot all be
folded immediately. The native path validates their IR, permits integer
arithmetic and reads only of those known host symbol fields, then uses the host
backend to compile the expression. Symbol values and host field addresses retain
host I64 width. Calls, target-memory reads and stores are rejected in this path;
emitted 32-bit target instructions are never executed by it. Ordinary target
array/default constant evaluation continues through its existing restricted path.

Inline code shares the native function's frame: four-byte saved EBP/return
address, eight-byte argument slots starting at EBP+8, and target-sized local
layout. `&local` in an assembly operand supplies the local's frame offset.
The function prologue/epilogue saves and restores EBX, ESI and EDI; inline code
may use them as scratch registers. Assembly must leave ESP/EBP and the direction
flag compatible with subsequent HolyC execution unless it intentionally performs
nonlocal transfer. It runs with the same direct ring-0 access as HolyC.

Absolute relocations, inline external imports/exports and assembly storage
relocations remain unsupported and produce compiler errors. This is not yet a
complete native assembler or a replacement for every bootstrap NASM module.
Instruction auditing remains required for the 386 baseline: rejecting 64-bit
registers does not establish that arbitrary user-supplied assembly uses only
80386 instructions. Embedded byte directives also do not bypass that requirement.

`python3 tools/test-i386.py --inline-asm` compiles through the shared HolyC parser,
links the native output and executes it in protected mode. The corpus checks
wide argument writes, loops, local assembly calls, branches between HolyC and
assembly, numeric branch addends, assembler arithmetic, named local offsets and
preservation of caller registers. Negative cases cover unsupported modes,
registers and absolute label addresses. Exported executable regions are audited
as 32-bit instructions. This is component evidence, not native self-hosting or
strict physical-386 verification.


## Bootstrap provider migration

Top-level USE32 assembly can already use the ordinary module export and REL32
import path. `Kernel/I386/SysTry.HC` now uses it for the real two-argument SysTry
entry, replacing the hand-built NASM module. The exception fixtures compile this
source inside TempleOS and link it against HolyC runtime services. This removes
one host assembler dependency; the remaining bootstrap/interrupt stubs
and full native compiler self-hosting still need migration and verification.

`Kernel/I386/ExceptContext.HC` also builds through this path, exporting the save,
invoke, resume and registration primitives as a relocation-free module. The
runner embeds the HolyC-generated code and resolves entry offsets from its
exports, so register/flag and task-switch checks exercise those exact bytes.


## Native argument-forwarding instructions (2026-11-06)

The inline frontend now accepts DEC on 32-bit registers/memory, PUSH from
32-bit memory, indirect CALL through a 32-bit register/memory operand, and
explicit SIB index scales 1, 2, 4 and 8. These are the actual forms used by
Kernel/I386/CallExtStrRuntime.HC's NativeCallArgs, rather than source changes to
avoid unsupported instructions. Existing register PUSH/POP/INC encodings remain
unchanged. Indexed operands still require a base register and reject ESP as the
index. Invalid scales and byte-sized PUSH/CALL/DEC remain rejected.

The focused driver tools/test-i386-inline-call.py packages the complete
NativeCallArgs helper verbatim from its runtime source, excluding only the
runtime-dependent CallExtStr wrapper. The previous image fails at DEC ECX in
build/i386-inline-call-before-v1. The candidate in
build/i386-inline-call-native-v1 passes mask 63: zero/one/three-argument calls,
64-bit return values and argument order, all four scales, DEC preservation of
carry while setting zero, and indirect memory CALL. It exports guest-compiled
function bytes and checks explicit x86 encodings for DEC, scaled memory PUSH,
register CALL and scaled MOV/ADD. Seven invalid-operand definitions are rejected,
each followed by successful arithmetic and rendered 42. Filesystem and unchanged
input checks pass. This is native compiler execution, not a cross-build substitute.

Both original bootstrap generations pass. The candidate cross-build in
build/i386-inline-call-cross-v1 passes the 96 BIOS/332 protected-mode 386 audit;
its source audit matches 1368 delivered files. The prior inline corpus also
passes unchanged through the KVM keyboard harness in
build/i386-inline-call-legacy-v1, including unscaled operands, character immediates
and a 270-NOP forward-jump span. The 16 MiB diagnostic boot in
build/i386-inline-call-minimal-v1 passes all 307200 welcome pixels; concurrent
execution does not establish the startup timing budget or full minimal suite.

The retained-build tool now offers --keyboard for paced KVM keyboard submission
with live WinMgr, while retaining its native build calls and persisted module
export/allocation-wrapper audits. It requires explicit --accel kvm --cpu 486,-fpu
--qmp-stdio. This avoids the observed older harness attempt in
build/i386-inline-call-native-nine-v1, which left the first build command at the
prompt without an INPUT LINE execution marker. That attempt was explicitly
stopped; its screenshot and terminal unchanged-input audit are retained.

The full nine-module run `build/i386-inline-call-native-nine-v2/result.json`
now passes at 64 MiB KVM `486,-fpu` with live WinMgr and paced keyboard commands.
It builds and persists ConsoleRuntime, CompilerRuntime, CompilerProbe,
FileRuntime, MemoryRuntime, BuildRuntime, EditorRuntime, DocDiagnosticRuntime
and Startup. The build provider loads exactly once after startup. Persisted
module parsing, export-set comparisons (with the existing compiler division
helper allowance), console allocation-wrapper checks and fresh rendered
arithmetic pass. The terminal audit confirms all 1,272 source/tool/image pins
unchanged (`terminal-audit.json`).

The follow-up `build/i386-inline-call-native-install-v1/result.json` passes
replacement of all nine installed providers with these exact guest-built bytes.
Replacement runs at 16 MiB; an independent writable copy cold-boots at 8 MiB
KVM `486,-fpu` with live WinMgr. Arithmetic returns 42, DocAllocationCheck
returns 13, and diagnostic growth recovery and one load/unload cycle pass.
Fresh rendered arithmetic also passes. The preserved source and candidate
images remain unchanged; `terminal-audit.json` verifies all seven pinned inputs.
The installer now supports the same explicit paced `--keyboard` mode.

This establishes native compilation, persisted module/export checks and
installation/functional boot for that frozen interface-213 input image. It
does not qualify the newer interface-220 sources. Two successive native
generations, byte reproducibility, the required TCG/resource/timing gates and
full C1–C5 release qualification remain open.

```
python3 tools/test-i386-inline-call.py build/i386-inline-call-cross-v1/kernel.img --out OUT_TEST
python3 tools/test-i386-retained-build.py --disk build/i386-inline-call-cross-v1/kernel.img --out OUT_BUILD --reference-exports build/i386-inline-call-cross-v1/exports --accel kvm --cpu 486,-fpu --ram-mib 64 --welcome --qmp-stdio --keyboard --command-timeout 7200
```

## Second native generation terminal result (2026-11-06)

`build/i386-inline-call-native-generation2-v1/result.json` fails exact installed
module comparison after all nine modules were built at 64 MiB KVM, CPU
486,-fpu, with live WinMgr and one build-provider load. This is frozen
interface-213 evidence, not qualification of the current interface.

The exhaustive comparison under its `comparison/` directory finds eight
byte-identical modules. ConsoleRuntime has the same 2,258,426-byte size but
differs at offsets 1,780,505 and 1,780,838. Both are bytes in immediate addresses
inside TermRightClickLink: 0x014091b8 in generation one and 0x0140dbb8 in
generation two. Its two DocForm calls use implicit lastclass arguments. The
parser emits a copied string for these defaults only under CCF_AOT_COMPILE,
while native command compilation clears that flag and retains CCF_MODULE_SOURCE.
This is the leading explanation; a focused module relocation regression and
fix are still required. The exact-comparison gate remains failed.

`terminal-provenance-audit.json` verifies 22 unchanged input paths and the
original preloaded build-helper snapshot and reader AST. The on-disk builder
hash differs, as recorded throughout the run; the original input manifest is
preserved. Do not describe all original path hashes as unchanged. No C5
completion is claimed.
