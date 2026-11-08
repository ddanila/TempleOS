# Shared JIT assembly fixups

`Compiler/CMain.HC` now includes the complete original `CmpFixUpJITAsm` body from
`Compiler/JITFixupCore.HC`. `CodeLabel.HC` and `LabelForwardCore.HC` provide the
actual label search and forwarding bodies. Reserved implementation-name macros
allow a system-lifetime native source service to reuse them without replacing
public compiler symbols. This checkpoint prepares that delivery; it does not
publish a native JIT binding or qualify another compatibility workflow.

The shared routine retains absolute add/sub patches at all four widths,
relative/immediate exports, deferred-import resolution, label/function/global
references, branch bounds, trace disassembly, and successful packet cleanup.
Relative calculations use an I64 patch address so a 32-bit pointer operation
cannot truncate a negative 64-bit displacement. Deferred resolution passes its
zero flags explicitly, and trace decoding selects 32 bits for an i386 target.
The original partial-progress exception cleanup policy remains unchanged and
is not qualified by this extraction.

`build/rebuild-test/result.json` and `build/jit-decoder-bootstrap-v5.log` record
two passing x86-64 compiler/kernel rebuild generations with these exact shared
source bytes. Both generations compile through the real shared CMain routine.
The preparation-source audit is retained as
`build/i386-jit-fixup-preparation-audit.json`.

Native delivery remains unfinished. Preserved Console 253 candidates under
`build/i386-jit-fixup-cross-v2` and `cross-v3` have an 8 MiB decoder-compilation
allocation failure. The source-on-first-use candidate loads its real JIT body,
but the full contract still fails when trace output parses `$$HL,1$$` under a
temporary caller hash-table head. Direct source-link lookups and a fresh-document
decoder probe pass; replacing the capture document does not fix that failure.
`build/i386-jit-trace-step-v1` isolates the failing highlight command before
instruction decoding. Native task/compiler ownership checks currently require
the owned symbol table itself as the task's current head; accepting temporary
linked scopes requires further ownership and cleanup work. These failures are
not passing JIT or resource qualification.

The unchanged original implementation passes the 40-assertion reference contract
in `build/i386-jit-fixup-original-v6`. That reference independently measures the
six diagnostic exceptions' retained heap cost rather than attributing it to JIT
metadata. Native parity, trace output, partial-progress unwind, 8 MiB startup,
normal public compiler delivery, 684 inventory workflows and the complete
C1–C5 release gates remain open.
