# i386 ABI working contract

Status: architecture decisions for the port; the experimental backends only
implements a subset of this contract. No compatibility claim follows from this
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
Shift counts use the low six bits, preserving the 64-bit value model on i386. Pointer-aware size
queries are used during parsing and scaling. Calls, variadic functions, module
relocation, floating-point output, switch dispatch and short-circuit/chained
comparisons remain pending.
Compile-time integer evaluation has a separately selected x86-64 host stub;
unsupported host expressions and `#exe` must fail rather than execute target code.
