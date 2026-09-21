# Retained public numerical providers

CompilerRuntime 48 publishes 13 numerical functions for normal native HolyC:
`Round`, `Trunc`, `Floor`, `Ceil`, `Pow10I64`, `Ln`, `Log10`, `Log2`, and the
original `FloorU64`, `CeilU64`, `RoundI64`, `FloorI64`, `CeilI64` operations.
`PublicMath.HH` supplies their public declarations during normal startup.

The software F64 helpers were previously exercised in standalone runners.
They now live beside the retained compiler's existing software arithmetic and
power-of-ten table, avoiding another copy of those providers. Integer multiples
use the shared original `KMathInt.HC` bodies, including their wrapping and
truncating-remainder behavior. This integration does not replace them with a
host-language definition of rounding.

A new `math_bind` callback expands the private compiler-service record from
204 to 208 bytes. The loader validates the new version and callback address
before use. Binding preflights the export namespace, publishes static records
without allocating, accepts repeat binding to the same table, and rejects null
or a different table after publication. The kernel owns both the symbol records
and the code for its lifetime. Diagnostic boot checks repeated/null binding and absence of duplicate `_ROUND`
exports. Normal boot performs only the required publication; interactive tests
also check that its symbol is unique.

These providers satisfy the numerical dependency of `StrPrintJoin`; complete
formatting still requires its date, file/document serialization, symbol-address
and output providers. Full DolDoc layout and editing remain unfinished.

## Numerical contract and integration checks

Rounding is fixed round-to-nearest/ties-to-even for `Round`; the other integral
operations use their named direction. Signed zeros and exceptional-result bits
follow the existing software policy. Logarithm comparisons allow one ULP for
`Ln` and two for `Log10`/`Log2` on finite corpus values, with exact exceptional
bits. This is the existing tested policy, not universal correctly-rounded or
bit-for-bit x87 equivalence. No FPU status flags or domain traps are provided.

`tools/gen-i386-public-math.py --check` regenerates the integration expectations
from the existing independent Python rational/integer and high-precision Decimal
oracles. The fixture stores binary vectors in escaped string literals, avoiding thousands
of initializer expressions during native compilation. It has 64 signed rounding-boundary vectors, 64
logarithm vectors, 64 integer-multiple vectors and all 617 supported powers of
ten. The logarithm oracle checks agreement at 160 and 220 decimal digits.

The native command check makes 4107 comparisons through retained public calls:
256 rounding, 192 logarithm, 320 integer-multiple, 617 power-of-ten bit patterns,
617 formatter exponent extractions, all 2098 representable binary powers through
`Log2`, and seven nested/indirect/side-effect and exponent-limit checks. The normal
boot sets CR0.EM and the build audits instructions. These integration vectors
complement the larger standalone numerical corpora; they do not redefine their
accuracy contract.

## Manual use

The normal HolyC prompt loads these declarations automatically. For example:

```c
Round(1.5);
Floor(Log10(Pow10I64(100)));
FloorI64(-7,3);
```

These return 2, 100 and -9 respectively. The numerical test fixture is loaded
only when requested; normal startup does not run its 4107 comparisons.

## Validated result and cost

Both x64 rebuild/reboot generations and the full QEMU/486 8 MiB native suite
pass. The prompt suite passes 201 commands / 264 input lines, including all
4107 public numerical comparisons, inherited definition lookup, four exact VGA
frames and 11 hardware breaks. Startup recovery and all 17 module rejection
checks pass. All 1154 source hashes, 16 build-input hashes and both disk hashes
match the tested files. The normal preview was refreshed from the verified disk.

Normal startup measured 24.135 seconds and separate diagnostics 136.985 seconds.
CompilerRuntime 48 retains 1341344 bytes (1341328-byte image), with a 208-byte
service record. ConsoleRuntime remains version 19 at 187672 retained bytes.
The kernel is 365760 bytes, leaving 23360 bytes of reserved-load headroom.
These are QEMU/486 results with x87 trapped; strict 386 and physical-PC
acceptance remain outstanding. Full editor peak memory and latency must still
be measured as part of the editing goal.
