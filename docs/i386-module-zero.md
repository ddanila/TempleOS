# Zero-initialized source-module storage

The full native kernel parsed successfully but failed module packing at the
uninitialized callback `i386_lex_doc_format`. Native source units stage static
data through the ordinary declaration parser with CCF_AOT_COMPILE temporarily
clear. That selected JIT initialization: use the configured byte pattern when
enabled, otherwise leave allocated bytes untouched. Original AOT instead writes
zero to its static data before applying explicit initializers.

The focused `tools/test-i386-module-zero.py` deliberately enables the public
JIT initialization flag and sets its byte to0xA5. The same source is compiled
by the original x64-to-386 AOT and the delivered native source builder. It
contains an uninitialized byte, I64, pointer, function pointer,37-byte array and
nine-byte record with a pointer, plus a fully initialized array and scalar.
Every uninitialized byte must be zero; explicit values must remain unchanged.
The public flag/value restore, a fresh42 executes, and prior native files must
remain exact. Comparison uses named data exports/ranges, since the two packers
use different valid layouts.

`module-zero-original-v2` passes the independent data model. The unchanged
ABI274 image fails at `module-zero-before-v2`: stage5 rejects global-pointers
zi_callback, returns-1, restores controls, runs fresh42 and preserves all prior
files. The first fixture's partial C-style array initializer was rejected by
the original itself and is retained as a prototype, not the regression baseline.

I386FrontendInitialize now zeros source-unit static storage. #exe retains the
JIT policy, and ordinary JIT compilation keeps its original controls. The
change applies to module storage generally, without a callback-name exception.
`module-zero-fixed-v1` passes all eight named data checks. The original module
is558 bytes and the native module602 bytes; their values and storage sizes
match exactly. `module-zero-jit-regression-v1` retains mask255 for globals,
static locals, scalar/array stack locals, pattern capture and restoration.

The candidate is `build/i386-module-zero-cross-v1/kernel.img`. It pins1868
sources and26 helpers and passes two source-matching classic rebuilds and the
386 audit. Only Kernel and CompilerRuntime differ from the preceding image;
Kernel differs because its build timestamp advances. Console ABI274 and
Compiler service ABI105 are unchanged, as are their interface layouts. The
bare kernel remains458744 bytes.

```sh
python3 tools/test-i386-module-zero.py --out ORIGINAL
python3 tools/test-i386-module-zero.py IMAGE --out NATIVE
python3 tools/test-i386-variable-init.py IMAGE --out JIT
python3 tools/test-i386-system-build-date.py IMAGE --native-kernel --out KERNELS
```

The native kernel check must still finish and verify two emitted modules. It
compares all native module bytes except each fresh eight-byte date, validates
export names/kinds against the cross module, and preserves the running kernel's
public date and prior files. This component check does not replace installed
native generations, their complete application/desktop suite, or C5 profiles.
Inventory stays2/686; full C1-C5 remain open.
