# Shared numeric and dot tokens

`Compiler/LexNumber.HH/HC` supplies LexNumberBody. The existing x86-64 Lex dispatch
and the native I386LexNumber adapter now use the same digit/dot parsing code.
It recognizes decimal, hexadecimal and binary integers, decimal fractions and
exponents, a dot, a double dot, and an ellipsis. This is a lexer component;
identifiers, character constants, operators, macros and directives still need
native integration before a complete lexer or compiler/JIT exists.

The caller has already consumed the first digit or dot and exclusively owns its
live compiler control and input. The shared CLexCharSource contract now lives in
LexInput.HH, independently of strings. The callback owns character delivery,
replay and file transitions. Native string and number adapters share the same
explicit heap/line-counter reader context and callback.

The shared body returns its token after updating cur_i64 or cur_f64 and the
existing replay/dot flags. Its caller performs the common final character read
and sets CCF_USE_LAST_U16, matching Lex's existing finalization. The native adapter
performs that final step and returns -1 if either the body or final read fails.
Failures can leave consumed input, flags and a partially published token; they
are not resumable parser continuations. The caller must abandon the parse or
explicitly restore/restart its input. Output field types retain I64/F64 widths.

## Lexical compatibility

The implementation retains observable legacy rules instead of applying C-style
literal validation. Accumulation and exponent arithmetic wrap in I64. A prefix
can follow a nonzero first digit (`1x2`, for example), an empty hex/binary body
retains its accumulated value, and exponent parsing accepts a minus but does not
consume a plus as an exponent sign. A number followed by two dots uses the saved
dot flag so subsequent calls produce the original range/ellipsis tokens. KEEP_DOT
and LAST_WAS_DOT preserve their existing effects and lookahead positions.

Before extraction, 1089 token records were captured from the x86-64 lexer at
`43e619b`. `tests/i386/lex-number-values.json` records the original revision,
input-file hash, token type, numeric bits, source offset, replay/dot flags, last
character and line number. `Capture.HC` contains the capture procedure; do not
regenerate this reference against the shared implementation being tested.
The x86-64 fixture still compares every field with that original capture.

## Floating-point policy and the remaining target boundary

The native parser uses the already established native Pow10I64 and software F64
policy: correctly rounded binary64 powers within -308..308, zero below that range,
infinity above it, signed-I64-to-binary64 conversion, binary64 multiplication, and
the runtime's canonical invalid NaN. This preserves the literal grammar and
accumulation rules, but does **not** promise x87 bit identity.

The original x86-64 power table contains approximations, and its expression
execution also has x87 precision behavior. Native and original F64 results differ
in 243 captured cases, including NaN sign differences. Every difference is recorded
in `tests/i386/lex-number-compatibility.json`. No tolerance is used to accept native
results: `tools/gen-i386-lex-number.py` independently derives their exact expected
bits using integer wrapping, rational powers, and host binary64 conversion and
multiplication. It does not use the target power table or numerical helpers.
Integer results and all token/lookahead state still match the original exactly.
See the prior numerical decisions in `i386-f64-backend.md`.

Cross-compilation still parses source literals in the x86-64 compiler host.
Selecting target numerical semantics for those literals, and reconciling them
with native compile-time evaluation/self-hosting, remains required work. These
fixtures expose that boundary; they do not establish identical floating-point
literal bits across the host cross-build and eventual native JIT.

## Verification and resident integration

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-number
python3 tools/test-i386.py --lex-string
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

Both rebuild/reboot generations and all subsequent suites pass. The numeric
fixture checks the original state record and native floating oracle, consecutive
range/ellipsis tokens, injected failures in each read of representative numeric
forms, invalid arguments, unsupported input modes and final-lookahead failure.
A native owned input ends after a hex prefix: a pending save point first rejects
its pop, and an explicit restart then parses the parent input and fully reclaims
the child. Existing string, snapshot, raw-input, bitmap and bit-intrinsic cases
also pass, together with executable instruction audits.

The numeric fixture runs on the 8 MiB QEMU/486 profile with CR0.EM set. Its separate
256 KiB test transfer ends at 0x50000; its first heap is at 0x60000. The larger
transfer accommodates the captured oracle and runtime, and is allowed only by
an explicit numeric-test boot flag. Other fixture stage bounds remain intact.

The 384664-byte resident kernel now includes the parser, software numerical
runtime and power table and passes the full 8 MiB boot/startup-rejection/keyboard/
VGA/timer suite. Its boot source pass remains raw character consumption: 14306
characters, 367 newlines, FNV32 0xF8D086D1 and 14768 reclaimed heap bytes. Numeric
parsing executes in the dedicated native fixture; the boot console is still not a
HolyC execution environment. The conventional-memory boot stage is nearly full;
remaining compiler/runtime residency needs a deliberate extended-memory module
layout. Full lexical integration, compiler/JIT, DolDoc/editing, self-hosting and
strict 386SX/DX validation remain open.
