# Integer-only binary64 runtime

`Kernel/I386/SoftF64.HH` declares `I386F64Add(U64 a,U64 b)` and
`I386F64Sub(U64 a,U64 b)`, plus `I386F64Mul(U64 a,U64 b)`. Arguments and return
values are binary64 **bit patterns**, passed through the ordinary native integer ABI. They do not perform
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
canonical quiet NaN.

Significands carry three guard/round/sticky bits. Alignment combines discarded
bits into a sticky bit, with explicit handling of shifts of 64 or more. Magnitude
ordering permits unsigned subtraction; normalization and rounding handle both
normal/subnormal boundaries and carry into the exponent. Multiplication normalizes
nonzero subnormal inputs, forms an exact 106-bit product using 32-bit limbs, and
reduces it to guard/round/sticky precision before the shared rounding step.
Underflow shifts with sticky preservation before rounding, including values
below half the smallest subnormal.

This is runtime groundwork. Native compiler lowering of HolyC F64 expressions,
other arithmetic, comparisons, conversions, formatting, math functions,
exception flags/traps, selectable rounding modes and optional 387 execution
remain unimplemented. NaN policy and precision differences from the existing x64
x87 implementation need compatibility testing before full language integration.
No full IEEE conformance or complete HolyC F64 support is claimed.

Run `python3 tools/test-rebuild.py`, then
`python3 tools/test-i386.py --soft-f64`. The fixture executes 2,048 operand pairs
and compares addition, subtraction and multiplication bit-for-bit against host
binary64 arithmetic, with explicit expected NaN propagation. It includes a cross-product
of special/boundary values, selected alignment distances, halfway cases, product
underflow/overflow, cancellation and deterministic random inputs. The host patches only the exported
oracle data region after cross-compilation. Function bytes pass the existing
386 instruction audit; the native runner sets CR0.EM to trap x87 use. QEMU's
486 model with 8 MiB is a development check, not real-386 or full-OS proof.

For the wider arithmetic surface and rounding-mode terminology, see the
[Berkeley SoftFloat interface documentation](https://www.jhauser.us/arithmetic/SoftFloat-3/doc/SoftFloat.html).
SoftFloat is a reference here, not a linked dependency or a conformance oracle.
