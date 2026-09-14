# i386 ABI working contract

Status: architecture decisions for the port; the experimental backends only
implement a subset of this contract. No compatibility claim follows from this
specification alone.

## Values and layout

Pointers and function pointers occupy four bytes. Explicit integer types retain
their namesake widths; I64/U64 and F64 occupy eight bytes. The target is little
endian. Pointer/integer conversion uses the low 32 bits when narrowing explicitly;
widening an address to U64 zero-extends. An IPtr representation is signed I32;
UPtr is U32. Checked allocation and image-loading interfaces reject overflow.
Negative pointer sentinels must be compared at target pointer width.

HolyC lvalue casts retain their storage-view semantics. Casting a four-byte
pointer variable as `I64` can read eight bytes at that variable's address; it is
not a value-widening operation. Use a value context to obtain the pointer value,
which is zero-extended by the i386 load path. Audit existing pointer casts with
this distinction in mind.

Preserve HolyC's packed class layout unless explicit alignment is requested.
Do not infer C compiler padding. Define every serialized record with fixed-width
fields; compiler-host object sizes are not target layout queries.

## Calls

The initial backend returns an I64 in EDX:EAX (EDX high). EAX returns a pointer
or a scalar up to 32 bits. F64 returns its binary64 bits in EDX:EAX as well, so
software and optional coprocessor implementations share the same ABI.

Use eight-byte scalar argument slots to preserve HolyC's existing variadic
`argc`/`argv` representation. A pointer is zero-extended into its slot. Signed
small integers are sign-extended; unsigned values are zero-extended. Stack
alignment is four bytes; eight-byte argument slots do not imply eight-byte
alignment for all objects. Push arguments right-to-left; the first argument is
at EBP+8 after the saved EBP and return address. The low dword of a slot is at
the lower address.

Fixed-arity functions use callee cleanup, matching HolyC's existing direction.
Variadic functions use caller cleanup with the argument-count slot and eight-byte
value slots. Default arguments are expanded at the caller and may occur between
explicit arguments. Specify and test hidden aggregate return storage before
supporting aggregate returns; do not inherit a platform C ABI accidentally.

EBX, ESI, EDI, EBP, and ESP are callee-preserved. EAX, ECX, EDX, and arithmetic
flags are clobbered. DF must be clear on entry and return. FS/GS are reserved for
task/CPU access; ordinary calls preserve their selectors. Interrupt and exception
entry has a separate fully specified frame before use in the ported kernel.

## Compiler staging

The x86-64 compiler host stores its own objects/pointers at their native widths.
Target instruction bytes are data until transferred to a 32-bit runner. They must
never be called in the host's long-mode execution context. Host generators and
target `sizeof`/`offset` queries must be distinguished explicitly.

The initial `Compiler/I386/Expr.HC` entry point feeds the existing HolyC parser's
unoptimized IR into a pair-of-dwords stack backend. It deliberately reports
unsupported opcodes instead of falling back to x86-64 output. It currently accepts
integer expressions, not functions, pointer-layout queries, or complete modules.

`Compiler/I386/Core.HC` adds the normal compiler function path through
`CmpI386Buf`. Its current subset implements fixed-arity scalar arguments,
integer arithmetic, comparisons, conditional branches, loops, local loads/stores,
increment/decrement, compound assignments, 64-bit shifts, casts and returns.
Shift counts use the low six bits, preserving the 64-bit value model on i386.
Signed division truncates toward zero; remainder has the dividend's sign.
Division/remainder by zero and signed MIN_I64 divided by -1 raise vector 0.
The i386 path bypasses the legacy power-of-two division-to-shift shortcut so
negative division retains the same rule with constant and variable divisors. Pointer-aware size
queries are used during parsing and scaling. Direct calls within a compilation
unit, forward fixups, recursion, nested calls, scalar slot extension, and integer
default arguments are implemented. Undefined functions are rejected during AOT
resolution. T32M objects support relative-call imports through the bootstrap
linker described in `i386-modules.md`. `&&`/`||` short-circuit in branch conditions,
including nested logical conditions; value expressions evaluate both operands,
matching the x64 backend. Boolean `^^` evaluates both operands. Truth tests use
all 64 bits, including the sign bit when the value holds an F64 pattern.

`ToBool` is now a native intrinsic, with a standalone declaration in
`Kernel/I386/Bool.HH`. It accepts the ordinary I64 argument and normalizes all
64 bits to zero or one before returning Bool. High-word-only and high-byte-only
values are not discarded before normalization. Nested intrinsic calls and
side-effecting argument expressions use the existing call tracking.

Integer math intrinsics now include `AbsI64`, `SignI64`, `MinI64`, `MaxI64`,
`MinU64`, `MaxU64`, `SqrI64`, `SqrU64` and `ModU64`, declared standalone in
`Kernel/I386/Math.HH`. They consume ordinary eight-byte argument slots and
return EDX:EAX. Min/max compare both words and select with branches; no CMOV or
later instruction is required. AbsI64 preserves MIN_I64's bit pattern, and
both square forms return the low 64 product bits, matching x64 overflow behavior.
SignI64 returns -1, zero or one. Nested calls and side-effecting arguments retain
the existing call evaluation rules.

`ModU64(U64 *quotient,U64 divisor)` reads the pointed value once, computes unsigned
quotient and remainder in one division, stores the quotient and returns the
remainder. Its saved destination uses the target's four-byte pointer width.
The division emitter has an unsigned mode returning both register pairs; existing
signed/unsigned division and remainder modes remain covered by regression tests.
Division by zero raises #DE before the quotient store. Full exception unwinding
is separate unfinished work.

Run `python3 tools/test-i386.py --integer-math` after the x64 rebuild test.
The fixture checks absolute/sign, min/max and square operations over the Cartesian product of 32 boundary
and bit-pattern values (8,192 results), plus 1,984 quotient/remainder results
for the 992 nonzero-divisor pairs. This includes signed extrema, equality,
high-word-only values and unsigned/signed ordering differences. Actual x64 output
must first match an independent Python arbitrary-precision integer oracle; native
execution then checks that oracle, plus nesting, side effects, shared operands
and decimal digit extraction. The general function fixture also verifies #DE
for a zero divisor. Instruction auditing and an 8 MiB QEMU 486 run are development evidence, not strict 386 proof.

Indirect fixed-arity calls share the direct-call ABI. The caller captures a
four-byte function pointer into an eight-byte evaluation slot before evaluating
arguments, calls through its low dword, and removes that saved slot after the
callee cleans up arguments. Callbacks can be local variables, parameters, or
class members. Function addresses within the same compilation unit, including
self-references and forward declarations, use position-relative code and compiler
fixups; moving the linked image preserves them. Version-2 modules also support
imported function and data addresses through relative address relocations. An unresolved plain
`extern` function address is a compile error.

Global/static storage has target-width layouts and constant scalar, array, and
packed-record initializers. Inferred global/static array lengths are supported.
Stores use the destination value type, including assignments to array elements.
Function code starts on eight-byte boundaries independently of packed data layout.
Address-bearing static initializers and executable initializers remain pending.

The shared module loader now executes on i386 with caller-owned output memory.
Resident kernel symbol binding and lifetime management remain pending.
Chained comparisons preserve each middle operand in an eight-byte frame slot,
then reuse it for the next comparison. Branch chains short-circuit and value
chains evaluate all operands. Nested chains have distinct slots; calls and
recursion cannot overwrite another frame's retained values.
Variadic calls, floating-point output and switch dispatch remain pending.
Compile-time integer evaluation has a separately selected x86-64 host stub;
unsupported host expressions and `#exe` must fail rather than execute target code.

Port-I/O intrinsics use the same eight-byte argument slots as fixed-arity calls.
The backend consumes each slot, uses the low 16 bits of the port and the low
8/16/32 bits of the output value, and zero-extends unsigned input results.
Output intrinsics have U0 return semantics. Nested intrinsic calls retain the
normal expression-stack and callee-saved-register rules.
