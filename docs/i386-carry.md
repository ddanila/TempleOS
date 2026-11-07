# Carry counter and shift workflow

The original public Carry intrinsic has opcode IC_CARRY (0x6D), returns I64,
and takes no arguments. The native declaration and signature validator use that
same contract. Compiler runtime 86 adds materialized Carry and the optimizer's
IC_BR_CARRY/IC_BR_NOT_CARRY plus IC_CALL_END2 forms.

Compiler bookkeeping preserves flags: scalar normalization uses
flag-neutral CDQ or PUSH/POP, and frame loads omit a redundant high-word clear; pointer address formation uses LEA;
unused-result and call-argument cleanup use LEA. Imported-address materialization
keeps the existing ADD-immediate ADDRESS relocation format and saves/restores
flags around both PC adjustments. No module format or export layout changes.
GetRFlags, segment/frame pointers, input-port results and bit-test result
materialization also preserve the flags that the underlying operation exposes.

The shared 386 shift emitter computes CF from the original 64-bit input's last
shifted-out bit, including the 32-bit boundary. Counts are masked modulo 64;
zero counts preserve the input value and flags. Signed and unsigned right shifts
retain their distinct value semantics. ESI/EDI/EBX are existing backend scratch
registers saved by generated function frames; no per-function flags allocation
or demo-specific lowering is used.

Run tools/test-i386-carry-operations.py --out OUT on the pinned original, or
supply a native image before --out. Its 608 value/carry pairs cover unsigned
64-bit add/subtract and signed/unsigned shifts: eight full-width patterns, both
carry seeds, counts 0/1/31/32/33/63/64/65/95/127. A separate Python mathematical
oracle checks every value and carry bit. Original-v2 produces 9,728 bytes with
SHA-256 7dfe2172a2935b2150636709c720bada5f5b3312dcae5937de635809cf52cfe7.
The v1 original fixture used an unsupported local aggregate initializer; its
terminal syntax failure is retained and is not carry-semantic evidence.

Run tools/test-i386-carry-demo.py --out OUT on the original, or supply a native
image before --out. It executes all of unchanged Demo/Carry.HC through ExeFile:
1,024 counter rows, 128 two-word shift rows, and 64 carry-branch bits. It then
finds the actual retained BigCnt/BigShift/Branch functions, releases the demo's
declaration input, churns 32 KiB on each allocator and calls all three again.
Each complete DolDoc document must match the independently generated 39,258-byte
mathematical oracle, including formatting and the final cursor record. Mask 7
requires actual function retention and identical nonempty captures. The original
initial/retained SHA-256 is
9fae6bab84ccdf632b5ce179e009606fee8910eaaf39571b9467cac6be9fbd45.
The delivered demo SHA-256 stays
15d52f01f897668959fccdfc52d9ebdf56e9d4c9f125e5a1c71b3aada542146d.

The pre-change native image rejects the actual demo at missing Carry, line 10.
The first runtime-86 candidate builds but fails root user-header publication
because its intrinsic validator still omitted Carry. Both failures and input
pins are retained; neither is a successful native workflow result.

These probes do not qualify every CPU flag, other arithmetic operators (such as
multiply/negate/increment), narrower-width carry behavior, inline assembly flag
blocks, other bundled applications, or complete C1-C5 release gates. The demo's
declarations and capture buffers intentionally persist until guest shutdown;
this is not a delete-all-declarations heap recovery test. Visual text is checked
as exact serialized DolDoc content; shared VGA rendering/startup is checked
separately by the welcome-frame oracle.

The final compact full-content candidate is build/i386-carry-runtime-cross-v3.
Original-v1 and native-v3 complete demo runs both pass mask 7 and both exact
39,258-byte documents. Original-v3 and native-v3 operation probes both pass all
608 pairs with the same 9,728-byte hash. Native normal arithmetic works after
each workflow, and the fixture is the sole volume addition. Independent terminal
audits verify the pinned inputs and original output equality. The existing
ClassMeta workflow also passes mask 511 and all three original documents on this
candidate (build/i386-carry-class-meta-native-v3).

Evidence: build/i386-carry-demo-{original-v1,baseline-v1,native-v1,native-v2,native-v3},
build/i386-carry-operations-{original-v1,original-v2,original-v3,native-v1,native-v2,native-v3},
and their result/terminal audit files. The complete demo requirement mapping is
build/i386-carry-demo-native-v3/workflow-qualification-audit.json. The exact shift
bytes were also executed as 386 instructions in a Linux i386 ELF, checking 480
shift pairs independently of the guest (build/i386-carry-shift-isa-v1).

The final operation fixture also stores/reloads a global after each add/subtract,
checking that imported-address formation and memory access retain carry. The
original-v3 and native-v3 records still match the independent oracle exactly.
The earlier v2 candidate passed the 64 MiB workflows and source23 suite, but
failed 8 MiB startup from code-size pressure. Compact flag-neutral extension and
pointer-slot sequences, plus removal of redundant frame clearing, reduced native
kernel bytes from 498,472 to 422,704 without changing the operation semantics.
The 8 MiB startup/welcome gate then passed all 307,200 pixels on the final image.
These failures and the earlier successful larger-memory results remain retained.

Final integration checks: both x86-64 bootstrap generations and all 1,759
cross-build source pins pass. Source23 on the final image passes every staged
publication and prior lexer/expression/type/class/statement/function contract;
all 1,032 input pins are independently checked. Seven actual shared-compiler
functions still execute after controller release, and code/metadata deletion
recovers both heaps exactly. The 16 MiB diagnostic image passes both program
phases, code-heap ownership transitions and file-break cleanup phases, followed
by normal startup and all 307,200 welcome pixels. Memory evidence is recorded in
build/i386-carry-memory-audit-v3.json. These checks do not establish the separate
C5 native-generation, full-suite and steady-state gates.

The inventory now has two defined qualified demo workflows and 684 unqualified
items. Full normal compiler delivery and complete C1-C5 remain open.

Runtime 87 adds differential multiply/square/negate/scalar-increment carry cases
and preserves pointer result types across shared optimizer folds. Both defined
Carry and ClassMeta workflows repeat successfully on that current candidate.
See docs/i386-carry-arithmetic.md for the 216 arithmetic triples, the separate
128-case runtime-index reference, ISA tests and limits; this demo document's
original 608-case/whole-demo scope does not imply full CPU-flag qualification.
