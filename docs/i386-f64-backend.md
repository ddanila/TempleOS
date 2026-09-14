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
These intrinsics do not yet enable implicit mixed-type conversions.

This is an initial compiler integration. Runtime mixed integer/F64 conversions,
mixed-type relations/compound assignments, raw F64 conditions,
remainder and math intrinsics remain unsupported and are rejected. Numeric
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
