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

### File-mask allocation cleanup (2026-11-01)

A temporary fault-injection stack trace (`build/i386-c5-alloc-stack-8m`)
identified both 25-byte requests as `FilesFindMatch`, called by `DocRecalc`
during `DocSave`. The first mask buffer was left allocated if the second
allocation threw. `FilesFindMatchCore.HC` now initializes all four temporary
buffer pointers and frees any acquired buffers on an exception before it
propagates. This also covers failures while constructing the path buffers or
in a nested file-mask match.

The original two-generation compiler/kernel rebuild and the full native
cross-build passed. Original and native file-mask fixtures passed all seven
behavior/heap groups with unchanged inputs (`build/i386-c5-files-find-oom-original`
and `build/i386-c5-files-find-oom-native`). The 16 MiB native startup
diagnostics, retained-code checks and exact VGA restoration passed
(`build/i386-c5-files-find-oom-diag16`). These runs overlapped other guest work
and do not establish startup timing.

On the fixed 8 MiB image (SHA-256
`a072ff00b6d4473764fd42c31fe7bf69a93c3ac97c4e2e9b4d2d8f69ce24d3f3`),
`DocAllocationCheck` advances from `-38` to `-42`: the first five paste
allocation failures preserve target bytes and heap usage, while the sixth
still fails the heap check. The strict `13` oracle timed out after the guest
displayed `-42` (`build/i386-c5-files-find-oom-8m`); an independent run
confirmed the exact `-42` result with unchanged disk input
(`build/i386-c5-files-find-oom-observed-8m`). This is an expected-failure
observation, not a passing install gate. The sixth failure's ownership remains
to be traced. Complete native installation, two native generations, timing and
C1–C5 qualification remain open.

### Save failure cleanup (2026-11-01)

The sixth injected paste failure was traced with temporary instrumentation.
In `build/i386-c5-sixth-stack-8m`, failure 6 increased task heap usage from
`0x6080` to `0x60E0` (96 bytes). A separate call-stack probe
(`build/i386-c5-sixth-malloc-8m`, image SHA-256
`7973e2a09df94a26cf745026c8ad5f99517d8db02ce663c2b24645d13eda58f8`)
identified the failed four-byte request as `DocSave`'s output allocation after
recalculation. The 96-byte increase is consistent with a cursor entry created during
recalculation. The probes were removed.

The shared `DocSave` now releases an allocated output buffer, removes any
remaining temporary cursor entries after completed recalculation, and unlocks
the document when saving throws. The original two-generation rebuild and the
native cross-build pass. At 64 MiB the native serialization fixture passes its
plain-text, exact saved bytes, cursor, binary-record, lock and heap checks
(`build/i386-c5-save-cleanup-save64-welcome`). Its harness now accepts
`--welcome`; the earlier attempt without this option timed out at the welcome
screen before issuing the fixture.

On the fixed 8 MiB image (SHA-256
`b289f024c6f3384a2ec8e87408c926735c18c379f4816db3e088dbf034dbfe7a`),
the strict `DocAllocationCheck` advanced from `-42` to `-12`
(`build/i386-c5-save-cleanup-8m`, guest screen). The first eleven injected
paste cases returned failure with matching target bytes and heap usage; case 12
returned success. The `13` oracle timed out, so the install gate remains
failing. Whether the twelfth fault was reached and its underlying cause remain
unconfirmed. The 8 MiB run overlapped other guests and is not timing evidence.

### Isolated paste faults and read cleanup (2026-11-01)

The apparent twelfth paste fault was not injected: a temporary count probe
(`build/i386-c5-paste-twelfth-8m`) recorded a 12-allocation baseline, fault
index 12, and only 11 allocations in that successful later paste. Reusing the
clipboard allowed `DocSave` recalculation to change its internal layout
between cases. The probe was removed. The diagnostic now creates an identical
clipboard for each case, checks that the requested fault index was reached,
and reconstructs the clipboard before comparing heap usage. This last step
removes document-owned layout changes from the leak measurement; the fixture
checks target bytes and task heap recovery, not exact clipboard entry layout.
With fresh inputs but before that restoration, the strict check reported
`-42` (`build/i386-c5-paste-isolated-8m`). With restoration it advanced to
`-104` in the following `DocRead` fault check
(`build/i386-c5-paste-reset-8m`).

`DocRead`'s exception path freed the document and file buffer but not its
absolute filename. It now frees that allocation before propagating the
exception. The original two-generation rebuild and native cross-build pass.
The strict `DocAllocationCheck` returns `13` with exact VGA checks on both 8
and 64 MiB (`build/i386-c5-docread-cleanup-8m` and
`build/i386-c5-docread-cleanup-64m`) using the unchanged source image SHA-256
`8d1182d6a26b4c850f9140de70da9a22ced9f15552a9d22fb7ee54d45ff3a600`.
These runs overlapped other emulation and do not qualify the startup time gate.

The cross-built Startup replacement probe now completes the file replacement,
verifies installed bytes, reboots at 8 MiB, and passes arithmetic and the strict
allocation diagnostic (`build/i386-c5-docread-install-probe`). Its Startup
module was cross-built and byte-identical to the installed provider; this does
not qualify a guest-built module, full installation, or native generations.

The separate nine-module retained build on the include-dollar image has since
finished with a ConsoleRuntime out-of-memory rejection in
`C:/Kernel/StrIMatchCore.HC` (`build/i386-c5-include-dollars-native-build`).
It had passed the previous `CLexFile` rejection but did not complete its first
module. The guest reported an allocation request of `0x7E` bytes and largest
free block of `0x48` bytes. This build used the earlier pinned image and does
not include the subsequent save/read changes. Resolving native build memory,
full guest-built installation, two generations and C1–C5 qualification remain
open.

The subsequent nine-module retained build on the shared-call-descriptor image
also failed its first module, ConsoleRuntime, with `OutMem` in the same source
file (`build/i386-c5-shared-calls-native-build/result.json`). Its pinned input
SHA-256 is `4f3d19cca69bf7246ec592d444e29550c279255e3d0fe08d1ec4ed2c7587abf2`;
it predates the version-77 token change. On 16 MiB `486,-fpu`, the guest
reported a `0x7A`-byte request, arena usage `0xD77AC0` of `0xD79C00`,
`0x14CFD` allocations, and a largest free payload of `0x48` bytes. The
difference between arena size and used spans is `0x2140` bytes, including free
block headers; it is not a count of available payload bytes. The failure
therefore shows insufficient contiguous space, not the identity of the
allocations causing fragmentation. No retained module was qualified by this
run. Full guest-built installation and two native generations remain open.

The retained-build harness now accepts `--ram-mib` for the supported 8, 16,
64 and 128 MiB profiles, defaulting to its previous 16 MiB. A nine-module run
at the plan's initial 128 MiB rebuild budget ran on the version-77 image
(`build/i386-token-refresh-retained128`); QEMU was launched with 128 MiB and
the guest reported its larger arena. This does not replace the minimal 16 MiB
regression requirement.

The version-77 128 MiB run subsequently failed while packing ConsoleRuntime
with `duplicate-function DocCursor` (`build/i386-token-refresh-retained128`).
The guest log recorded two starts for `DocCursor`. ConsoleRuntime included
`DocVisibilityCore.HC` and `DocMaxCore.HC` directly and again through
`DocRecalcLib.HC`; the two direct includes have been removed. The original
two-generation rebuild and native cross-build with its 386 boot audit pass
(`build/i386-doccursor-dedup-rebuild.log` and
`build/i386-doccursor-dedup-cross.log`). The native visibility contract passes
at 64 MiB on image SHA-256
`70c6388ed30ff100b8b67cbb1bede56af80662fdcfb8362a66b930895d0b72e9`
(`build/i386-doccursor-dedup-visibility/result.json`); it does not test visual
rendering or concurrent updates. The original rebuild reports binary
differences and is not a reproducibility pass.
The native `DocMax` contract also passes on that image, covering the entry
maximum, previous return, zero, default and absent documents
(`build/i386-doccursor-dedup-docmax/result.json`); it does not test automatic
document truncation. Both focused contract runs preserved their inputs.

A 16 MiB startup diagnostic on the corrected diagnostic image passes its
startup, retained-value, storage and exact VGA checks
(`build/i386-doccursor-dedup-diag16-contract/result.json`, input SHA-256
`ce3bf7197c6f8f37adc5312e58021ca34b0c80e2b5f27a612920343b2fd6bff1`).
It ran alongside other guests and does not establish the timing gate.
A fresh nine-module 128 MiB retained build on the corrected image failed its
first module (`build/i386-doccursor-dedup-retained128/result.json`). It passed
the earlier duplicate-function pack rejection and reached stage 6, staged
module writing, with a queried size of `0x27F946` bytes. The guest reported a
generic `Compiler` exception; this does not identify whether allocation,
streaming, validation or staging failed. No module was retained, and the pack
fix is not qualified by a completed native module. The run's input was the
image identified above; it predates subsequent FAT work. Full installation,
two native generations, the timing gate, and C1–C5 qualification remain open.

Failure-only diagnostics now distinguish metadata allocation, span allocation,
invalid spans, and the remaining validation-or-sink failure; stage 6 also logs
the writer result and staged byte count, expected size and phase when it throws.
They do not change the serializer's acceptance rules. Both original rebuild
generations, the native cross-build and 386 instruction audit pass
(`build/i386-stage6-diagnostic-rebuild.log` and
`build/i386-stage6-diagnostic-cross`), as do the existing module-writer and
stage contracts (`build/i386-stage6-diagnostic-writer` and
`build/i386-stage6-diagnostic-stage`). Those contracts do not demonstrate the
new diagnostic on the large failing unit. The 8 MiB initial welcome-screen check
also passes (`build/i386-stage6-diagnostic-welcome-8m`), but its concurrent run
does not qualify the full minimal profile or timing gate.

A fresh nine-module 128 MiB retained run with those diagnostics is in progress
(`build/i386-stage6-diagnostic-retained128`). Its input SHA-256 is
`d5843a084afd9a5b83fabbd7f3503554749063e4a504d161cacccfc371dee656`.
No result is claimed until it finishes; the preceding stage-6 failure remains
unresolved.
A separate Startup-only retained build passed on that image at 128 MiB with
`486,-fpu` (`build/i386-stage6-diagnostic-startup128/result.json`): it built a
407-byte module with six records and one export. This does not resolve the
larger ConsoleRuntime failure or qualify the full retained build.

Read-only comparison of the failed run's final disk against its pinned input
found one new sector-aligned T32M header with the reported `0x27F946` size at
sector 98732. Within its 5117-sector extent, 989 sectors differ from the input,
ending at relative sector 988 (`build/i386-doccursor-stage-remnant.json`; tool
`tools/inspect-i386-module-stage-remnants.py`). The recovered image's
`ModuleWriteCore.HC` matches the current source. That writer validates the
module before emitting its header, so this is evidence that validation passed
and streaming began. Changed sectors are not an exact count of writes: writing
identical bytes would not appear in the comparison. The failure offset and
whether the sink, staging state or another streaming condition caused it remain
unknown.

The streaming writer now builds a 512-byte relocation bitmap per 4 KiB payload
window instead of scanning every record for every output chunk. It retains the
existing sink chunk sizes, validates before writing, and still invokes the
payload reader for each byte. For the earlier failed ConsoleRuntime header
(2,332,112 payload bytes, 2,619,718 total bytes and 9,985 records), this reduces
the calculated record-loop iterations from 51,093,245 at 512-byte chunks to
5,691,450; that is an iteration count, not a measured runtime improvement or
evidence that the stage-6 failure is fixed. The bitmap adds 512 bytes to the
writer's stack frame.

The original-system writer contract passes against the contiguous packer for
the existing cases and five scratch sizes with relocation slots crossing 4 KiB
window boundaries (`build/i386-module-writer-window-v3`). Both original rebuild
generations pass with binary differences (`build/i386-module-writer-window-rebuild.log`),
and the native cross-build and 386 instruction audit pass
(`build/i386-module-writer-window-cross`). The concurrent 8 MiB boot reached
native startup but failed the input harness's expected VGA upload sequence:
the log recorded the initial 60-row upload without the expected prompt upload
at that checkpoint (`build/i386-module-writer-window-welcome8`). This run is
not a timing qualification. A separate exact initial welcome-pixel check passes
at 8 MiB with unchanged inputs (`build/i386-module-writer-window-welcome8-v2`);
it does not check that upload sequence. A Startup-only native build passes at
128 MiB (`build/i386-module-writer-window-startup128`), producing a 407-byte
module with six records and one export. This checks native serialization only
for a small module; the older nine-module diagnostic remains active on its
earlier image.

Validation now shares the same 512-byte page bitmap with the serializer,
instead of scanning every relocation record for each requested code byte. The
cache handles backwards page requests and patch slots split across pages; the
serializer retains the payload-reader and sink behavior. The updated
original-system oracle covers ordered and reverse-ordered records across page
boundaries at five scratch sizes, as well as an invalid maximum record offset
and a direct maximum-offset cache check (`build/i386-module-validator-window-v6`).
The original compiler and kernel rebuild through two generations with binary
differences (`build/i386-module-validator-window-rebuild.log`), the native
cross-build and 386 instruction audit pass
(`build/i386-module-validator-window-cross`), and the separate 8 MiB exact
welcome-pixel check passes with unchanged inputs
(`build/i386-module-validator-window-welcome8`). A Startup-only native module
build passes at 128 MiB (`build/i386-module-validator-window-startup128`),
producing the same 407-byte module hash as the preceding windowed writer.
This reduces repeated scans when validation accesses nearby offsets, but no
elapsed-time gain or resolution of the large stage-6 failure is claimed.

A native multi-page probe generates 160 functions and builds them in the
guest (`tools/test-i386-module-writer-pages-native.py`). The preceding writer
image passes (`build/i386-module-writer-pages-native-control-v1`): the persisted
module is 24,069 bytes with 161 exports and 320 relocation slots across three
payload pages. The validation-cache image's corresponding run is still live
at `build/i386-module-validator-pages-native-v1`; it has compiled the functions
and reached packing but has not produced a result. A temporary trace image and
smaller probe are running at `build/i386-patch-map-trace-cross` and
`build/i386-patch-map-trace-native-v1`. This observation is not yet a terminal
failure or a timing comparison. The production source does not include the
temporary trace statements.

The validation cache is now disabled pending investigation. The preceding
writer image completed the multi-page probe, while the cache-image probe has
remained live in packing far longer without a result. A temporary direct native
probe with 481 records timed out on repeated cache calls
(`build/i386-module-cache-direct-many-v1`); a loop-only control passed
(`build/i386-module-cache-loop-control-v1`), and a one-call probe displayed zero
where its fixture expected one (`build/i386-module-cache-direct-one-v1`). A
separate native control checked all 320 populated record kinds and offsets
(`build/i386-module-cache-record-control-v1`), while a two-record direct probe
passed (`build/i386-module-cache-direct-v1`). These
direct probes use a fixed address in the pinned image and are diagnostic, not
a general public-API test. Their difference warrants the conservative rollback,
but it does not establish the exact fault. The earlier 4 KiB output-window
optimization remains; the live cache-image, trace and nine-module runs are
not stopped by this source change. The rollback writer oracle passes
(`build/i386-module-validator-rollback-writer-v1`), as do both original rebuild
generations with binary differences (`build/i386-module-validator-rollback-rebuild.log`),
the native cross-build and 386 audit (`build/i386-module-validator-rollback-cross`),
and the 8 MiB exact welcome-pixel check with unchanged inputs
(`build/i386-module-validator-rollback-welcome8`). Its native multi-page probe
passes (`build/i386-module-validator-rollback-pages-v1`), producing the same
24,069-byte module hash as the preceding writer image, with 320 relocation
slots across three payload pages.
