# Carry for multiply, negate and scalar increment

The next public Carry differential contract covers 216 triples: the expression
result, the stored result and Carry. It uses variable U64/I64 multiplication,
SqrU64/SqrI64, U64 negate, and pre/post scalar increment/decrement with both
incoming carry seeds. Eight full-width patterns include zero, one, the 32-bit
boundary, the signed minimum, all ones and mixed high/low words. The original
compiler uses unsigned MUL for U64 and signed IMUL for I64, including the square
intrinsics (Compiler/BackA.HC and OptPass789A.HC).

The independent Python oracle forms the complete mathematical product. Unsigned
carry means the product exceeds U64_MAX; signed carry means it does not fit I64.
NEG carry means its input is nonzero. Scalar INC/DEC preserve incoming carry,
including wrap and the distinction between pre/post expression results.
Original-v2 passes every 5,184-byte record with SHA-256
ee682a3b41cd2cbf7fd808ae7423078fabc98709f22edad4bc92fa7ac0b7db63.
The baseline native image has 107 carry mismatches and no numeric-result
mismatches. Its exact record, fixture, runner and independently checked input
pins are preserved in build/i386-carry-arithmetic-baseline-v2.

Run tools/test-i386-carry-arithmetic.py --out OUT for the pinned original, or
supply the normal native image before --out. No replacement compiler or arithmetic
function is source-loaded into the test system. The sole added file is the
fixture; boot bytes, image contents, later normal arithmetic and input hashes
are checked by the runner. Fixture declarations and result storage intentionally
remain until guest shutdown, so this does not prove declaration deletion or
heap recovery. The earlier 200-triple v1 reference/baseline is retained; v2 adds
both actual square intrinsic paths without changing the other operations.

Compiler runtime 87 forms a complete 128-bit product using four 32-bit MUL
instructions. Twenty temporary stack bytes retain the original limbs and low
result word; signed products subtract each negative operand's sign correction
from the upper half. It returns the original low 64-bit result and sets CF from
the complete upper half. Signedness comes from the actual IR result class or
square intrinsic, rather than treating signed overflow as unsigned overflow.
The helper uses the backend's existing scratch registers and no heap storage.

NEG sets carry from the whole 64-bit result, which is nonzero exactly when its
input was nonzero. Scalar INC uses a low-word INC and increments the high word
on wrap. Scalar DEC complements/increments/complements the low word, decrementing
the high word on borrow. These sequences preserve incoming CF throughout. The
existing pointer-step and floating-point paths are separate and unchanged.

Before guest integration, the exact multiply chunks were executed as 386
instructions in a Linux i386 ELF. Both signedness modes match all 64 boundary
pairs and 4,096 seeded random pairs each (8,320 total). The production emitter
chunks are checked byte-for-byte against those executed chunks; evidence and
the reproducible ISA harness are in build/i386-carry-multiply-isa-v1.

This contract does not qualify all CPU flags, pointer increment carry, arbitrary
inline assembly flag blocks, narrow-width arithmetic behavior, every public
compiler service, other application workflows, or complete C1-C5 release gates.

## Pointer result metadata and addressing

The first two native candidates still returned zero carry after the second
indexed result store. Actual CANegate machine code identifies the clobber:
ADD EAX,ECX / ADC EDX,EBX at byte 76 computes the constant-index pointer after
NEG. The shared optimizer promotes ic_class for arithmetic and the next fold
copies that over ic_class2. Looking at ic_class2 only at emission was too late.
The final backend restores pointer-plus-integer result types from the operand
trees in IR order after each shared fold. This handles nested pointer adds,
uses no allocation, and does not change the original shared optimizer body.
The same observed function now emits LEA EAX,[EAX+ECX] and a flag-neutral zero
high word at that location. Both source bodies and complete arithmetic records
are unchanged; only export-only code observation was added in the debug runs.
See build/i386-carry-operator-debug-{v1,v3}/machine-code-audit.json.

Runtime indices are a different reference case. The extra 128-triple contract
covers indexed unsigned 1/2/4/8-byte loads and stores, indices 0..7 and both
incoming carry seeds. Its original and baseline records are identical: runtime
index arithmetic produces zero carry in these cases. The first address runner
incorrectly expected the incoming seed to survive; its failed original oracle
is retained and explicitly marked invalid, rather than called a native defect.
The corrected byte/value and scale-arithmetic oracle passes original-v2,
baseline-v2 and final native-v3 with 3,072 identical bytes, SHA-256
8123332a201d7e22605805fad054e375d414e6c86b0aa483872983eb7f2adde8.
Run tools/test-i386-carry-addresses.py [IMAGE] --out OUT to repeat it.

The final 216-triple native-v3 arithmetic record matches original-v2 exactly,
including the carry after the constant-index store. All 10 pinned inputs and
both complete original output records are independently checked at terminal.
Earlier candidates and the intentionally cancelled source/diagnostic v2
verification remain visible; cancellation is not a passing result.

The tracked host ISA check is:
python3 tools/test-i386-multiply-emitter.py --out OUT
It extracts the literal production chunks, checks their encoded lengths and
executes 8,320 boundary/random signedness cases. Its seeded mixed-width sample
set exercises both fitting and overflowing products; the separate guest probes
remain the normal compiler acceptance evidence. Final host evidence is
build/i386-carry-multiply-emitter-v1/result.json.

## Final integration evidence

Final image: build/i386-carry-arithmetic-cross-v3/kernel.img, runtime 87,
454,184 native kernel bytes. Both x64 bootstrap generations and all 1,759 source
pins pass. Final native arithmetic and address probes match every original byte;
all 608 earlier add/subtract/shift pairs also match. Both qualified demos repeat:
Carry mask 7 and its two complete original documents, and ClassMeta mask 511
and its three original documents. Normal public member lookup (4095), single-table
hash lookup (1023) and lexer save points (8191) pass with independently checked
inputs, including counter wrap, adjacent data and heap ownership checks.

The final source23 suite publishes all 23 stages, passes every prior contract,
executes seven real shared-compiler functions after controller release and
recovers both heaps on code/metadata deletion. All 1,032 source-suite input pins
are independently checked. The 8 MiB normal and 16 MiB diagnostic startup gates
each match all 307,200 welcome pixels; 16 MiB passes both program, code ownership
and file-break cleanup phases. See build/i386-carry-arithmetic-memory-audit-v3.json
and the corresponding terminal-integration-audit.json files.

No new whole-application workflow is qualified by this arithmetic checkpoint.
The inventory remains at two defined qualified demos and 684 unqualified items.
Full public compiler delivery and C1-C5, including the separate C5 native
rebuild generations/full suite/resource/startup budgets, remain open.
