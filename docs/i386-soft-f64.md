# Integer-only binary64 runtime

`Kernel/I386/SoftF64.HH` declares `I386F64Add(U64 a,U64 b)` and
`I386F64Sub(U64 a,U64 b)`, plus `I386F64Mul(U64 a,U64 b)` and
`I386F64Div(U64 a,U64 b)`, `I386F64Abs(U64 value)` and
`I386F64Sqrt(U64 value)`. Arguments and return values are binary64 **bit
patterns**, passed through the ordinary native integer ABI. They do not perform
integer-to-floating-point conversion. The implementation uses only integer HolyC
operations and requires no third-party runtime.

The initial contract is fixed round-to-nearest, ties-to-even, gradual underflow,
signed zeros and infinity on overflow. Exact cancellation produces positive zero;
adding two negative zeros produces negative zero. Subtraction applies the sign
change after NaN classification. The first NaN operand is quieted while retaining
its sign and payload; otherwise the second NaN is quieted. Opposite infinities in
addition (equal infinities in subtraction) produce `0x7FF8000000000000`.
Multiplication uses the XOR of operand signs
for finite results, zero and infinity; zero times infinity produces the same
canonical quiet NaN. Division uses the same sign rule; zero divided by zero
and infinity divided by infinity produce the canonical quiet NaN. Other
division by zero produces signed infinity; finite values divided by infinity
produce signed zero. These operations do not yet raise floating-point flags.

Significands carry three guard/round/sticky bits. Alignment combines discarded
bits into a sticky bit, with explicit handling of shifts of 64 or more. Magnitude
ordering permits unsigned subtraction; normalization and rounding handle both
normal/subnormal boundaries and carry into the exponent. Multiplication normalizes
nonzero subnormal inputs, forms an exact 106-bit product using 32-bit limbs, and
reduces it to guard/round/sticky precision before the shared rounding step.
Underflow shifts with sticky preservation before rounding, including values
below half the smallest subnormal. Division normalizes the operand significands
and produces 56 quotient bits by shift/subtract long division. A nonzero final
remainder sets the sticky bit; shared rounding then handles normal and subnormal
results. Shifted remainders fit in 54 bits, so no 128-bit divide is required.

`I386F64FromU64(U64 value)` and `I386F64FromI64(I64 value)` convert actual
integer values to binary64 bit patterns. Both use nearest-even rounding; zero
converts to positive zero. The signed path computes magnitude with unsigned
subtraction, including `I64_MIN`. Values above 2^53 may round; in particular,
`U64_MAX` rounds to the binary64 representation of 2^64. Normalization preserves
sticky information before the shared rounding/packing step. Explicit native `ToF64` now selects the signed helper, matching its I64
parameter contract and x64 boundary tests. Supported implicit conversions use
the same signed conversion path.

`I386F64Compare(U64 a,U64 b)` returns -1 for less, 0 for equal, 1 for
greater, or `I386_F64_UNORDERED` (2) when either operand is a NaN. Both signed
zeros compare equal; infinities and finite negative values follow numerical
order. Quiet and signaling NaNs both return unordered without changing operands
or raising exception flags. Compiler lowering must explicitly distinguish 1
from unordered: `>` uses result == 1, and `>=` uses result == 0 or result == 1.
Equality uses result == 0, inequality result != 0, `<` result == -1, and `<=`
result == -1 or result == 0. This helper does not define F64-to-Bool conversion.

`I386F64ToI64(U64 value)` converts binary64 bits to a signed integer by
truncating toward zero. Values with magnitude below one become zero. NaNs,
infinities and values outside the signed range return integer indefinite
(`0x8000000000000000`), matching the masked x64 `FISTTP` result used by `ToI64`.
That bit pattern is also the valid result for exactly -2^63; it is not a distinct
error code. The helper does not yet record invalid/inexact exception flags.

Initial native lowering now supports same-type F64 arithmetic, storage and calls;
see [compiler integration](i386-f64-backend.md), including relations and supported implicit conversions.
other arithmetic, explicit unsigned output conversion, formatting, math functions,
exception flags/traps, selectable rounding modes and optional 387 execution
remain unimplemented. NaN policy and precision differences from the existing x64
x87 implementation need compatibility testing before full language integration.
No full IEEE conformance or complete HolyC F64 support is claimed.

Run `python3 tools/test-rebuild.py`, then
`python3 tools/test-i386.py --soft-f64`. The fixture executes 2,048 operand pairs
and compares addition, subtraction, multiplication and division bit-for-bit
against host binary64 arithmetic, with explicit expected NaN propagation.
It includes a cross-product
of special/boundary values, selected alignment distances, halfway cases, product
underflow/overflow, quotient remainder rounding, cancellation and deterministic
random inputs. The host patches only the exported
oracle data region after cross-compilation. Function bytes pass the existing
386 instruction audit; the native runner sets CR0.EM to trap x87 use. QEMU's
486 model with 8 MiB is a development check, not real-386 or full-OS proof.

`python3 tools/test-i386.py --soft-f64-convert` runs a separate 1,024-input
fixture, checking signed/unsigned runtime interpretations and compiled `ToF64`
(3,072 conversions)
against Python integer-to-binary64 conversion. It covers every power-of-two
boundary, signed extrema, even/odd halfway rounding and seeded random values.
This fixture uses the same native instruction audit and CR0.EM trap setting.

`python3 tools/test-i386.py --soft-f64-compare` checks 1,024 operand pairs
against host numerical ordering and NaN classification, then checks the reversed
order (2,048 comparisons). The corpus includes signed zeros, subnormal/normal
boundaries, infinities, quiet/signaling NaNs and seeded random/adjacent values.
The fixture also runs with CR0.EM set and passes the generated-function audit.

`python3 tools/test-i386.py --soft-f64-to-int` checks 1,024 binary64 inputs
against both actual x64 HolyC `ToI64` results and independently computed host
truncation/range checks. It includes signed neighborhoods of all powers of two
from 1 through 2^63, subnormals, infinities, NaNs and deterministic random values.
The native fixture uses the same integer instruction audit and CR0.EM setting.
This proves conversion result bits for the corpus, not x87 exception-state parity.

For the wider arithmetic surface and rounding-mode terminology, see the
[Berkeley SoftFloat interface documentation](https://www.jhauser.us/arithmetic/SoftFloat-3/doc/SoftFloat.html).
SoftFloat is a reference here, not a linked dependency or a conformance oracle.

The same `--soft-f64-to-int` fixture now also checks compiled `ToBool` for all
1,024 inputs, both as variable F64 arguments and as raw U64 patterns. The former
truncates through I64 before truth testing; the latter tests all original bits.
Together with direct/compiled ToI64, this is 4,096 native checks. The host validates
2,048 actual x64 Boolean outputs against the corresponding numeric/raw oracle.
Constant-folding behavior is documented in `i386-f64-backend.md`.

`I386F64Abs` clears the sign bit and quiets any NaN while preserving its payload.
It maps negative zero to positive zero and negative infinity to positive infinity.
This matches the tested x64 Abs result bits, including signaling NaNs; exception
flags are still not implemented. Compiled `Sqr` reuses multiplication with equal
operands, retaining the multiplication rounding and NaN policy.

The `--soft-f64-unary` corpus includes signed exponent-boundary neighborhoods,
subnormal and square underflow/overflow edges, infinities, NaNs and deterministic
random bit patterns. Abs and integral rounding match x64; square and square-root precision differences are recorded
in the compiler integration document. All 13,312 native helper/intrinsic/public-function checks
pass without a coprocessor. This corpus does
not prove universal x87 intermediate-precision or exception-state equivalence.


`I386F64Sqrt` preserves signed zero and positive infinity, quiets NaNs while
retaining their sign/payload, and returns x64's negative indefinite NaN
(`FFF8000000000000`) for negative nonzero inputs, including negative infinity.
It does not report floating-point exception flags.

Positive finite inputs are normalized to a 53-bit significand, extended to 54
bits when making the exponent even. A two-word 112-bit radicand yields a 56-bit
root through 64 two-bit extraction steps and a bounded U64 remainder. The final
remainder supplies sticky information to the common nearest-even rounder. No
floating-point instructions, division approximation or external library is used.

The square-root oracle independently uses Python arbitrary-precision `isqrt`
and compares the squared midpoint exactly before packing a 53-bit significand.
It includes minimum subnormal, maximum finite and exponent-boundary cases. Native
execution matches this oracle, including the two observed x64 double-rounding
differences listed in `i386-f64-backend.md`.


`I386F64Round`, `I386F64Trunc`, `I386F64Floor` and `I386F64Ceil` return integral
binary64 bit patterns. They mask fractional significand bits and increment the
magnitude when the selected direction requires it; nearest rounding resolves
halfway values to even. Results that round to zero preserve the input sign.
NaNs are quieted with sign/payload preserved; infinity and already-integral values
are unchanged. These operations do not read or modify an FPU control word or
report exception flags. Public F64 wrappers live in `FloatMath.HC`.
