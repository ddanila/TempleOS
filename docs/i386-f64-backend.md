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

This is an initial compiler integration. Remaining math intrinsics and F64 bitwise/shift operations require further
integration. Numeric
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
`--soft-f64-to-int` performs 4,096 native result checks against its 1,024-input
x64/host oracle: two numeric conversions and two Boolean interpretations per input. The main F64 fixture additionally checks nested conversions and
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
coverage for missing/malformed remainder providers and F64 bitwise operations.

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


`ToBool` now lowers to an integer truth test through the standalone declaration
in `Kernel/I386/Bool.HH`. Its I64 parameter means a variable F64 argument first
uses the existing numeric truncation path. Thus variable -0.0 and 0.5 convert
to false, while passing their U64 bit patterns directly tests all bits and
returns true. Invalid numeric conversions use the existing nonzero
integer-indefinite result. The conversion fixture compares both interpretations
against 2,048 actual x64 ToBool outputs, as well as the independent host oracle.

The shared optimizer retains an existing constant-folding distinction:
`ToBool(0.0)` folds to false, but `ToBool(-0.0)`, `ToBool(0.5)` and
`ToBool(-0.5)` fold to true. Actual x64 checks and a native constant-expression
case verify these results. This preserves the observed constant/variable
behavior; it does not make `ToBool(F64)` equivalent to a raw F64 condition.


F64 `Abs`, `Sqr` and `Sqrt` are declared in `Kernel/I386/Float.HH`. These template
intrinsics have no ordinary call-start/end nodes, so the backend lowers them
as unary expressions while preserving any surrounding call context. `Abs`
uses the one-U64-argument `I386F64Abs` helper; `Sqr` evaluates its argument once
and passes the same binary64 value twice to `I386F64Mul`. Integer arguments
use the existing F64 conversion path. `Sqrt` uses the one-argument
`I386F64Sqrt` helper. All three operations require their runtime
providers and use the existing declaration/ABI validation and relocations.

`python3 tools/test-i386.py --soft-f64-unary` checks 1,024 patterns against an
independent host oracle and actual x64 output for seven operations. It executes
13,312 native checks (three compiled intrinsics, four public rounding functions
and six direct helpers), plus nested templates,
integer-argument/postfix side effects and a surrounding ToI64 call. Six negative
compilation cases reject missing providers and malformed unary helper declarations.
CR0.EM execution and generated-instruction audits pass. Trigonometry,
remaining numerical operations and floating-point state remain unfinished.


Square root uses correctly rounded binary64 results. Actual x64 execution differs
by one ULP at four tested inputs, consistent with rounding first to an x87
64-bit significand and then to binary64. The host comparison explicitly checks
these observations while native execution must match the exact integer oracle:

| Input bits | Native binary64 root | Observed x64 root |
| --- | --- | --- |
| `5FEFFFFFFFFFFFFF` | `4FEFFFFFFFFFFFFF` | `4FF0000000000000` |
| `7FEFFFFFFFFFFFFF` | `5FEFFFFFFFFFFFFF` | `5FF0000000000000` |
| `432FFFFFFFFFFFFF` | `418FFFFFFFFFFFFF` | `4190000000000000` |
| `3FEFFFFFFFFFFFFF` | `3FEFFFFFFFFFFFFF` | `3FF0000000000000` |

Square also differs for two magnitudes (both signs). Rounding the exact square
first to a 64-bit significand and then to binary64 reproduces these x64 results:

| Input magnitude bits | Native square | Observed x64 square |
| --- | --- | --- |
| `3FF7FFFFFFFFFFFF` | `4001FFFFFFFFFFFF` | `4001FFFFFFFFFFFE` |
| `4004000000000001` | `4019000000000003` | `4019000000000002` |

All other unary outputs in the corpus match x64. Full x87 precision/exception-state
compatibility remains unresolved. The `--float` and `--soft-f64-unary` fixtures use the existing
128 KiB boot-transfer path because their code and data exceed 64 KiB; RAM stays
8 MiB. This is runner capacity, not a change to the OS memory target.


`Kernel/I386/FloatMath.HH/HC` provides the ordinary public F64 functions `Round`,
`Trunc`, `Floor`, and `Ceil`, calling the bit-pattern helpers from SoftF64.
`Round` uses nearest/even; the other functions round toward zero, negative
infinity and positive infinity respectively. No conversion through I64 occurs,
so large finite values and infinities remain representable. The 1,024-input
corpus covers signed zeros, subnormals, NaNs, half-integers and their neighbors,
and the 2^52 integral boundary. All four operations match actual x64 output and
an independent Python oracle. Side-effecting arguments and nested public calls
also pass. Formatting still needs exception handling and
other production dependencies before StrPrintJoin can be integrated.


`Pow10I64` is now provided by `Kernel/I386/Pow10.HC`, included by FloatMath.
Its 617 U64 entries are generated from exact rational powers and rounded to
binary64, with no runtime allocation, transcendental calculation or FPU use.
`tools/gen-i386-pow10.py --check` verifies the checked-in table. The public
function preserves HolyC's range contract: exponents below -308 return +0;
exponents above 308 return +infinity. In particular, it does not extend the
API to smaller subnormal powers. The unary fixture adds all 617 in-range values,
four out-of-range/extreme inputs and nested/side-effect checks. Its oracle parses
decimal powers independently of the generator's rational conversion.

The x64 startup table and lookup now use index `i+308` rather than `i+309`:
617 allocated entries map to indices 0 through 616. Both initialization sources
were corrected, and the guest compares every public lookup with direct x64
`Pow10`. The x64 routine's approximation differs from the exact table for 607
exponents, with a maximum distance of 683 ULPs. The fixture pins the observed
x64 output digest and writes every difference to `pow10-compatibility.json`.
These differences remain explicit; native powers must match the exact oracle.
The combined unary/power corpus now checks 13,929 native results, plus the
existing additional call/edge cases. General Pow and Pow10 remain
unfinished, as does production formatting integration.


`Ln`, `Log10` and `Log2` now use `Kernel/I386/FloatLog.HC`, included by FloatMath.
This is a HolyC adaptation of fdlibm's
[e_log.c](https://www.netlib.org/fdlibm/e_log.c) and
[e_log10.c](https://www.netlib.org/fdlibm/e_log10.c), with the Sun permission
notice retained. It keeps the range reduction, polynomial coefficients and
compensated reconstruction. Coefficients use explicit binary64 bit patterns;
word extraction and insertion use U64 operations. The compiler now accepts an
I64-immediate opcode carrying F64 type after an explicit bitwise constant cast.
All arithmetic executes through the existing software F64 backend.

All three logarithms quiet NaNs while preserving sign/payload, return -infinity for
both zeros, preserve +infinity, and return negative indefinite NaN for negative
nonzero values. They do not report floating-point flags or raise domain traps.

Run `python3 tools/test-i386.py --soft-f64-log`. Its 1,024-input corpus covers
exponent boundaries, subnormals, neighborhoods of one and sqrt(2), exceptional
values and deterministic random positive patterns. An independent Decimal
oracle computes each finite result at 160 and 220 decimal digits and requires
both to round to the same binary64 result. The 3,072 native results must be
within one ULP for Ln and two ULPs for Log10 and Log2, with exact exceptional-result bits;
actual x64 results are independently checked against the same limits. These are
verified corpus limits, not a proof of correct rounding for all inputs or
bit-for-bit x64 equivalence. Nested calls, integer conversion and argument side
effects also pass. All 617 `Floor(Log10(Pow10I64(i)))` cases return `i`, checking
the exponent extraction used by formatting. The runner sets CR0.EM and audits
instructions; this remains QEMU 486 development evidence rather than strict
physical 386 validation.


Log2 uses the same normalization to keep the mantissa near one, then reconstructs
`exponent + Ln(mantissa)/ln(2)` with a binary64 inverse-ln(2) coefficient. Keeping
the exponent separate avoids cancellation for inputs near one and preserves
exact binary powers. The test requires exact results for all 2,098 representable
positive powers of two, from the minimum subnormal through 2^1023, and checks
argument side effects. The two-ULP corpus tolerance for other finite values is
not a claim of universal correct rounding. General exponential/power functions,
trigonometry, exception state and production integration remain unfinished.


F64 `%` and `%=` now use the exact integer-only `I386F64Mod` helper, including
mixed operands and integer destinations. The expanded F64 fixture passes 8192
remainder checks and eleven x64/native update checks, with NaN payload policy
recorded separately. See [i386-f64-remainder.md](i386-f64-remainder.md).
