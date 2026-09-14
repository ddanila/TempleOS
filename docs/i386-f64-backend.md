# Initial native HolyC F64 lowering

The i386 function backend now transports F64 as eight-byte binary64 bits in
EDX:EAX and eight-byte argument/evaluation slots. Pointers remain four bytes.
It supports F64 literals, local/global storage, pointer loads/stores, bitwise
HolyC typecasts, direct and indirect fixed-arity calls, and returns. Unary minus
flips the sign bit, preserving zero and NaN payload bits.

Same-type F64 `+`, `-`, `*`, and `/` call the corresponding integer-only
`I386F64Add`, `I386F64Sub`, `I386F64Mul`, and `I386F64Div` runtime helpers. The
source must expose their declarations, normally through
`/Kernel/I386/SoftF64.HH`, and link their implementation. The backend validates
the two-U64-argument/U64-result ABI, stages arguments in the ordinary native call
order and emits existing relative call fixups. Forward definitions, already
compiled definitions and declared imports use the existing module mechanisms.
There is no fallback to executing host function addresses.

Same-type F64 `==`, `!=`, `<`, `>`, `<=` and `>=` call `I386F64Compare` and
normalize its result to integer zero or one. Either NaN makes `!=` true and all
other relations false; signed zeros compare equal. The resulting integer can
control ordinary branches. The comparison helper declaration returns I64 while
its two arguments retain the U64 bit-pattern ABI.

Same-type F64 `+=`, `-=`, `*=`, `/=` and prefix/postfix `++`/`--` now use
the software arithmetic helpers. The destination address is retained across the
helper call and evaluated once. Increment/decrement use binary64 1.0; postfix
returns the original bit pattern while prefix returns the stored result. This
also preserves a signaling NaN or negative zero in the postfix result when the
updated value differs.

Explicit `ToF64` and `ToI64` intrinsics now call the one-argument software
helpers. Standalone sources include `/Kernel/I386/Float.HH` as well as the runtime
header and implementation. `ToF64` takes I64, matching `KernelB.HH`; passing U64
preserves the existing signed interpretation of its argument bits. True unsigned
conversion remains available through `I386F64FromU64`. `ToI64` truncates and uses
the documented integer-indefinite result for invalid inputs. Existing optimizer
rules also preserve already-integer/already-F64 inputs without a lossy round trip.
Implicit conversions now also apply to supported mixed arithmetic/relations,
assignments, function arguments and returns. F64 destinations accept integer
operands in compound updates. Conversion runs when the producer places its value
on the evaluation stack, before consumers use it; return-type conversion runs
before ABI normalization. The backend refreshes operand links after optimizer
rewrites and treats logical results as integer booleans, including when they are
subsequently converted to F64.

Integer destinations now accept F64 operands in `+=`, `-=`, `*=` and `/=`.
The backend converts the loaded integer to F64, performs the operation, truncates
the result to I64 and normalizes it to the destination width before storing.
It preserves the right operand across conversion and evaluates the destination
address once. U64 retains the signed interpretation used by x64 HolyC.

Raw F64 conditions and `!`, `&&`, `||`, `^^` now use the ordinary integer
truth test on the complete binary64 pattern, matching the x64 backend. Only
positive zero is false: negative zero, subnormals, infinities and NaNs are true.
This differs from comparing numerically against 0.0. Logical results in the
native backend are integer zero or one. No floating-point helper is needed.

HolyC short-circuits `&&`/`||` when they directly control a branch, including
through nested logical operators and negation. Value expressions evaluate both
operands; `^^` evaluates both. The i386 backend now distinguishes these contexts
instead of short-circuiting every logical expression.

Chained comparisons now reuse each middle operand through a dedicated frame
slot, saved before comparison runtime calls. This supports signed/unsigned
integers, F64 and mixed conversions, while keeping comparison results integer
booleans independently of operand-precision metadata. The existing logical
context handling provides short-circuit branches and eager value expressions.

This is an initial compiler integration. Remainder and math intrinsics remain
unsupported and are rejected. Numeric
conversion uses different semantics from a HolyC bitwise typecast and must not be
implemented as register normalization. Constant folding still uses the shared
host optimizer; numerical precision compatibility across folding and runtime
needs further tests. Floating-point flags, configurable rounding, full native
JIT/self-hosting and the production OS remain unfinished.

Run `python3 tools/test-rebuild.py`, then `python3 tools/test-i386.py --float`.
The native fixture checks arithmetic through functions, literals, local/global
and pointer storage, unary sign changes for zeros/NaNs, nested calls, indirect
F64 callbacks, both forward/direct helper fixups, compound updates and all four
increment/decrement forms. Pointer-producing calls count destination evaluations;
additional checks cover postfix signed-zero/signaling-NaN preservation and
nearest-even increments that leave a large value unchanged. Eight negative compilation
checks cover absent/malformed runtime declarations and unsupported operations. The test
runs with CR0.EM set and audits generated instructions. `--functions` retains
integer/call regression coverage; software-runtime numerical corpora remain
separate. QEMU 486 execution is not strict-386 or complete-OS validation.

`--soft-f64-compare` now also executes compiled HolyC branches for all six
relations over 1,024 operand pairs in both orders (12,288 operator checks), while
retaining the 2,048 direct-runtime comparisons. A second expression test uses
all six comparison results in integer arithmetic, including division of a boolean
result. The backend distinguishes result types from retained operand metadata.
Expected numerical ordering and
NaN classification come from the host oracle. x64 operator/exception-state
compatibility remains a separate unfinished check.

The conversion fixtures now check compiled intrinsic calls as well as direct
runtime helpers: `--soft-f64-convert` performs 3,072 native result checks and
checks eight signed-boundary results against actual x64 `ToF64`;
`--soft-f64-to-int` performs 2,048 native result checks against its 1,024-input
x64/host oracle. The main F64 fixture additionally checks nested conversions and
preservation of already-correct operand types.

The main F64 fixture now has 62 positive checks, including mixed operands in both
orders, assignment/call/return conversion, F64 compound updates with integers,
signed interpretation of U64 bits, and conversion of comparison/logical results
in nested expressions. Integer-destination updates additionally cover all
four operations, returned values, negative truncation, narrow storage overflow,
U64 interpretation, counted pointer destinations and NaN conversion. Eight x64
comparison checks confirm wide-integer results and addressed I8/U8 storage.

An existing x64 quirk remains explicit: register-held narrow locals can retain
out-of-range results (`I8 -127 -= 2.5` yielded -129 and `U8 250 += 10.5` yielded
260); addressed storage instead yielded 127 and 4. The native backend normalizes
all stored destinations to their declared width, including stack-backed locals.
This is a known difference for those out-of-range register temporaries, not a
claim of complete x64 expression compatibility. Unsupported-source checks retain
coverage for mixed remainder updates and F64 bitwise operations.

A shared x64/native condition fixture checks 144 pairs of 12 binary64 patterns.
Each pair checks five branch predicates, four logical values used in integer
arithmetic, and six operand-evaluation counts, including nested short-circuit
branches. Twelve additional cases exercise while, for and do/while conditions.
The shared arithmetic expression explicitly bitcasts `!a` to I64: the x64 backend
retains F64 precision metadata on uncast negation, and `return (!a)+2;` with F64
positive zero was observed to return 2. The native backend's integer boolean
returns 3, tested separately. This remaining x64 metadata quirk is documented
rather than treated as evidence of complete expression compatibility.


The chain fixture exercises 512 triples across signed four-operand chains,
unsigned chains, F64 chains and both mixed-type middle-operand arrangements.
It compares chain results against separate pairwise comparisons and checks
branch/value operand-evaluation counts. The integer fixture additionally covers
nested chains, chained equality/inequality and descending relations, arithmetic
uses of chain results, constants and a function-produced middle operand.

Actual x64 execution agrees for the checked integer/unsigned chains, evaluation
counts, same-type F64 value chains and mixed chains with F64 middle operands.
Two x64 differences are recorded instead of silently changing the native oracle:
29 of the 512 F64 branch cases disagree with separate comparisons, all with a
NaN first operand; 130 of the mixed chains with an I64 middle operand disagree.
For example, x64 `0.0 < I64_one < minimum_positive_subnormal` returns true, while
separate numeric comparisons and the native chain return false. The fixture
checks those observed mismatch counts; native execution must match separate
numeric comparisons for every case. Complete compatibility with these x64
quirks and floating-point exception state remains unresolved.
