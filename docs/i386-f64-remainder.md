# Native binary64 remainder

`I386F64Mod(U64 a, U64 b)` supplies the truncating remainder used by HolyC `%`.
Arguments and results are binary64 bit patterns in the existing integer ABI.
The i386 backend now lowers F64 `%` and `%=` through this helper, including
mixed integer/F64 expressions and integer destinations. This removes a numerical
dependency blocking native execution of the shared constant-folding pass.
The complete pass still needs its other runtime and frontend dependencies.

For finite operands and nonzero divisor, the result is exact and has the dividend's
sign, including an exact zero. The divisor's sign does not affect it. Finite values
modulo infinity return the dividend. An infinite dividend or zero divisor produces
negative indefinite NaN (`0xFFF8000000000000`), matching the tested x64 operation.
NaN inputs use the existing software-runtime policy: quiet the first NaN, retaining
its sign and payload, or quiet the second if only it is NaN. Floating-point status
flags and traps are not implemented by this helper.

The implementation normalizes the integer significands, subtracts and shifts the
remainder across the exponent difference, then packs the exact result. Shifted
remainders fit in 54 bits; no rounded quotient, FPU, 128-bit division or allocation
is needed. At most 2097 exponent-reduction steps cover the full binary64 range.
Subnormal remainders remain exact multiples of the minimum subnormal.

Compiler lowering preserves the existing checked two-U64-argument/U64-result
runtime declaration. Forward and already-defined helpers use ordinary native
fixups. Compound updates retain the destination address across the helper call
and evaluate it once. Integer destinations convert through the existing signed
I64/F64 policy, truncate the remainder and normalize the stored width; U64 retains
the existing signed interpretation in mixed arithmetic.

## Evidence

`python3 tools/test-i386.py --float` now includes 2048 deterministic operand pairs:
all pairs of signed boundary patterns, 512 wide-exponent/subnormal-divisor cases,
and 512 pseudo-random pairs. Python computes the expected finite result using
exact rational arithmetic and verifies exact binary64 representability. The
1700 non-invalid, non-NaN cases also agree with host `math.fmod`.

Actual x64 HolyC execution agrees bit-for-bit with the exact oracle on all 1808
cases without NaN inputs. The remaining 240 pairs verify quiet-NaN output; six
have different payload selection from the native first-NaN policy. This is an
explicit runtime policy difference, not finite-result rounding tolerance.

The native fixture checks each pair through the helper, an indirect F64 call,
a call after the helper definition and `%=`: 8192 exact checks with CR0.EM set.
Eleven additional x64/native checks cover mixed operands, integer/narrow
storage, U64 interpretation, signed zero, returned assignment values, counted
destination evaluation, large-integer conversion and NaN-to-integer behavior.
Absent and malformed remainder-provider declarations remain rejection tests.
The expanded F64 fixture uses a 160 KiB test-stage reservation.

Both x64 rebuild/reboot generations, the 233-case integer/function regression,
the existing 8192-case software arithmetic corpus and the complete standalone
kernel suite pass. These are QEMU/486 development
results with executable-region instruction audits; strict 386SX/DX hardware
acceptance remains open. Host constant folding still uses the original x64
optimizer; general cross-build/native numerical-policy integration remains work.
