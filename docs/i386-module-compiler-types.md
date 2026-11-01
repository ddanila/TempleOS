# Native module compiler-type regression

The full retained-module attempt on the current 16 MiB image rejected
ConsoleRuntime at `Compiler/LexFiles.HH` line 11, where `CLexFile` should have
been declared by `Kernel/CompilerTypes.HH`. A smaller module that includes that
header and uses `CLexFile` reproduces the failure
(`build/i386-c5-lex-minimal-native`). The image's copies of both headers match
the checkout byte for byte. The first console-scope lookup experiment found
neither the header guard nor the class, but does not establish the private
module's scope (`build/i386-c5-lex-scope-probe-v2`); an earlier long-command
probe timed out before executing (`build/i386-c5-lex-scope-probe`).

Temporary build-provider and compiler traces show the parser enters
`CIntermediateCode`, then reaches `CCmpGlbls` without reporting the intervening
classes, including `CLexFile` (`build/i386-c5-lex-class-trace-native`). These
instrumentation changes were discarded. On that diagnostic image, test copies
of the whole header with its first in-class `#assert !($$&7)` removed did
create `CLexFile` and reached module packing
(`build/i386-c5-full-header-noassert`). This is evidence of an interaction,
not authorization to remove the assertion or a complete root-cause diagnosis.
Plain assertions, anonymous unions, forward declarations, inheritance and a
small two-assertion case each reached packing in reduced diagnostic modules
(`build/i386-c5-assert-isolation`, `build/i386-c5-forward-isolation`,
`build/i386-c5-two-assert-probe`). Exact first-class header fragments with and
without the assertion also reached packing (`build/i386-c5-header-fragment`).
Those exploratory runs inspect guest logs; they do not audit generated modules
or qualify those language features generally.

A reusable regression now requires the unchanged full header, checks that
`CLexFile` has nonzero size, builds and persists a module, validates its layout
and checks its probe export. On the current non-instrumented image it correctly
fails at `Invalid class ... CLexFile`, while the following command completes and
all pinned inputs remain unchanged (`build/i386-c5-compiler-types-regression-red`).
The final runner additionally exits unsuccessfully if input integrity fails.

```sh
python3 tools/test-i386-module-compiler-types.py IMAGE --out OUTPUT
```

The compiler defect, full native retained build, installed generations and
C1–C5 remain open. The original header and its assertions are unchanged.

## Include-document dollar preservation

The assertion token trace shows that the lexer loses the dollar expression at
the first assertion and reads its next number at the later assertion
(`build/i386-c5-assert-token-trace-probe`). A byte-level trace shows that the
include document has already reduced the doubled dollar to one byte before the
lexer receives it (`build/i386-c5-assert-byte-trace-probe`). The original
`LexDocRead` sets `DOCF_DBL_DOLLARS` before `DocLoad`; the native include
document constructor did not. It now sets that flag before loading, preserving
the original document-based include behavior and the original assertions.
The temporary traces are not retained in production source.

Both original rebuild generations, the full cross-build and 386 audit pass
(`build/i386-c5-include-dollars-rebuild.log`,
`build/i386-c5-include-dollars-cross`). The previously failing full-header
regression now passes, including persisted module layout and export validation,
with inputs unchanged (`build/i386-c5-include-dollars-types`). Nested document
includes, document-based AOT module output and repeated include/error cleanup
also pass with unchanged inputs (`build/i386-c5-include-dollars-document`,
`build/i386-c5-include-dollars-aot`, `build/i386-c5-include-dollars-cleanup`).
The 8 MiB full startup completed all nine functional and VGA checks but failed
the 60-second timing assertion (`build/i386-c5-include-dollars-startup`); that
run overlapped other guests and is not a performance comparison.

The 16 MiB startup diagnostic also passes
(`build/i386-c5-include-dollars-diagnostics`). A new full nine-module native
retained build is running from the fixed image and matching export contracts
(`build/i386-c5-include-dollars-native-build`); it has passed the previous
`CLexFile` rejection and reached later headers, but has not completed or audited
any module. Its input image SHA-256 is
`45d9c7d6cd8f1b09981943b59a2668da2085f484853eaaf8706f8cf02483e4bc`.
