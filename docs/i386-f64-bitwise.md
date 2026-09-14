# Native HolyC F64 bitwise and shift operations

The i386 backend now accepts F64 `&`, `|`, `^`, `<<`, `>>` and their compound
assignments. These supply further operations used by the shared constant-folding
pass. They use the existing integer register-pair instructions; no new software
arithmetic helper or retained-service ABI is needed.

## Preserve the two HolyC operand rules

Ordinary binary forms operate on binary64 **bits**. An integer operand in a mixed
expression is first converted to F64 through the existing signed conversion
policy, then its binary64 representation participates in the operation. The
result retains F64 type. A shift takes the low six bits of the right operand's
binary64 representation as its count; F64 right shift is arithmetic. These are
not multiplication/division by powers of two, and they do not quiet NaNs.

Compound forms follow a different rule in `OptPass012`: convert an F64 right
operand to I64 first, then operate on the left destination's stored bits. An
integer right operand stays integer. The resulting shift count is the low six
bits of that integer. Right shift uses the destination's signedness, so a U64
destination shifts logically, while F64 and I64 destinations shift arithmetically.
An invalid F64-to-I64 conversion uses the existing integer-indefinite bits.
Destinations are evaluated once and normalized to their declared storage width.

The mixed tests found and fixed an i386 shift-selection defect: the backend used
the original left type even when that operand had been promoted from U64 to F64.
Variable and constant shift lowering now consult `I386ValueClass` for the effective
operand type, including conversion flags. Integer/function regressions cover the
shared shift path after this change.

## Verification

The F64 fixture uses the existing 2048 remainder input pairs, including signed
zeros, subnormals, infinities, NaNs, wide exponent gaps and deterministic random
patterns. Actual x64 execution produces two result arrays, independently checked
by Python integer operations and the documented F64/I64 conversions:

- 30720 results: five binary forms, five compound assignment results and their
  five stored values per pair.
- 53248 results: both mixed operand orders, promoted-U64 right shifts, signed and
  unsigned integer destinations, and F64 destinations with integer right operands.

The same 83968 checks pass natively with CR0.EM set. Four further x64/native
checks exercise counted pointer destinations, unquieted bit results, truncating
shift counts, narrow storage and U64 logical shifts. Existing remainder,
arithmetic, condition, chain and malformed-provider checks also pass.

A known narrow-result difference is explicit: `I8(-127) ^= F64(254.5)` through an
address stores 127 on both targets, but x64 returns -129 in the wider expression
temporary. The native backend returns the normalized stored value, 127, consistent
with its existing narrow-store policy. The fixture requires these exact distinct
results; it does not treat arbitrary mismatches as acceptable.

Successful commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --float
python3 tools/test-i386.py --functions
python3 tools/build-i386-kernel.py --test
```

Both x64 rebuild/reboot generations, all 233 integer/function cases, the expanded
F64 fixture and the complete standalone suite pass. Executable-region instruction
audits remain enabled. This is QEMU/486 development evidence, not strict physical
386SX/DX acceptance.

F64 complement, remaining math functions, floating-point status/traps, the full
native parser/optimizer/JIT and compiler/kernel self-hosting remain unfinished.
Cross-host constant folding still uses the original x64 optimizer; this change
supplies native execution of these operations without replacing that frontend.
