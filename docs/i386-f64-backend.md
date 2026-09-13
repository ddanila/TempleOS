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

This is an initial compiler integration. Runtime mixed integer/F64 conversions,
relational operators, F64 conditions, increment/decrement, compound assignment,
remainder and math intrinsics remain unsupported and are rejected. Numeric
conversion uses different semantics from a HolyC bitwise typecast and must not be
implemented as register normalization. Constant folding still uses the shared
host optimizer; numerical precision compatibility across folding and runtime
needs further tests. Floating-point flags, configurable rounding, full native
JIT/self-hosting and the production OS remain unfinished.

Run `python3 tools/test-rebuild.py`, then `python3 tools/test-i386.py --float`.
The native fixture checks arithmetic through functions, literals, local/global
and pointer storage, unary sign changes for zeros/NaNs, nested calls, indirect
F64 callbacks, and both forward/direct helper fixups. Eight negative compilation
checks cover absent/malformed runtime declarations and unsupported operations. The test
runs with CR0.EM set and audits generated instructions. `--functions` retains
integer/call regression coverage; software-runtime numerical corpora remain
separate. QEMU 486 execution is not strict-386 or complete-OS validation.
