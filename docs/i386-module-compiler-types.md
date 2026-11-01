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

## Welcome-aware generation harnesses

The retained-install, flat self-host install, and two-generation orchestration
harnesses now accept an explicit `--welcome` and pass it to their guest boots.
The default remains the prior plain-screen expectation. The option is recorded
in their result metadata; the full two-generation path remains untested until
all nine retained modules have built and passed their export audits.

An installation probe packaged a byte-identical **cross-built** Startup module
into the fixed image, replaced the installed copy, verified matching bytes,
and reached a fresh 8 MiB boot with the welcome screen
(`build/i386-c5-welcome-install-probe`). This does not qualify a guest-built
module or the full installation: the boot's `DocAllocationCheck` returned
`-38` instead of its required `13`, and the harness correctly failed. An
independent 8 MiB snapshot of the preceding image also returned `-38`
(`build/i386-c5-docalloc-baseline`), so the observation predates the include
flag change. The cause and exact failure stage within the diagnostic remain to
be established. The baseline was concurrent with the retained build, and its
startup timing is not an isolated measurement.

### Allocation-failure investigation (2026-11-01)

The existing `DocAllocationCheck = -38` install gate was investigated with
uncommitted diagnostic instrumentation on the 8 MiB guest. The diagnostic
reported 12 allocations for the successful clipboard paste and selected the
second allocation for failure; its task heap usage rose from `0x6080` to
`0x60A8` (40 bytes) across that failing paste. The instrumented allocation
trace recorded two consecutive 25-byte requests, with the second failing.
The paste's saved-buffer assignment had not completed: the exception occurred
inside `DocSave` before it returned to `NativeDocClipPaste`. This narrows the
leak to work performed by `DocSave` or its callees, but does not identify the
allocation's owner or establish a fix. Temporary tracing was removed.

The instrumented artifacts are `build/i386-c5-paste-trace-8m`,
`build/i386-c5-paste-body-trace-8m`, and
`build/i386-c5-paste-alloc-trace-8m`; they are local build evidence, not
committed fixtures. The strict install gate remains failing and C1–C5 remain
open. The nine-module retained build on the include-dollar fix was still
running in ConsoleRuntime when this note was recorded; it had reached
`RandI16`, with no complete module result yet.

A further instrumented 8 MiB run (`build/i386-c5-save-location-8m`, image
SHA-256 `8dbb5946f0aff3b87cc4b229d8fb151e9a0f36a3971171bd2b1271c7f6dfc127`)
reproduced `-38`. Both failing-allocation attempts occurred after entering
`DocSave` and before its bin-validation/recalculation stage completed, ahead of
the final output-buffer allocation. The markers do not distinguish
`DocBinsValidate` from `DocRecalc` or their callees.

A separate trace (`build/i386-c5-recalc-location-8m`, image SHA-256
`7bcd380f0c85148aed338a89099d3d11cf85ee0239f777c2cc131803ae539a3e`)
logged allocation indices and the text-merge allocation in `DocWordWrapDel`.
In the successful paste, the two initial 25-byte requests preceded the merge
allocation, which was allocation 5 and requested 3 bytes. The failed second
25-byte request occurred before any merge marker. This rules out that merge
allocation as the retained 40-byte charge in this fixture; it does not identify
the owner of the first request. Both observations used temporary instrumentation
and an expected-failure `-38` oracle, not a successful install gate. Instrumented
sources were removed after building the images.
