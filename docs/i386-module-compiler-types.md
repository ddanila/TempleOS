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
