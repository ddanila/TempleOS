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

The native kernel check passes at `module-zero-native-kernels-v1`. Two complete
native builds at128MiB produce541825-byte modules with all394 expected export
names/kinds. Every byte matches except each fresh eight-byte build timestamp.
The running kernel's public date remains unchanged; fresh42 passes and the full
prior file tree is preserved. This closes the recorded kernel packing failure.

`tools/test-i386-native-kernel-boot.py` links an emitted native Kernel with the
five existing boot helpers using I386BuildBootImage. It writes that module into
a copied full volume and publishes its boot area through I386InstallBootImage
onto a target whose boot area starts blank. The test independently checks all
boot-area bytes, preserves every prior target file except the replaced Kernel
module, and boots the installed target in a separate486,-fpu guest. Both public
build-date value and address must match that native module, with exact managed
welcome/command pixels and fresh42. Booting must leave the installed image exact.

`module-zero-native-kernel-boot-v1` passes for the first emitted module. The
linked flat kernel is465984 bytes, and its public build date resides at
0x16D3E8. The observed first module captured while the second build ran is
byte-identical to the final first output; the boot test uses those actual bytes.
This is one native Kernel component installed with existing cross-built resident
providers, not a fully native OS generation. Two complete installed native
release generations, the application/desktop suite and C5 profiles remain open.
Inventory stays2/686; full C1-C5 remain open.

```sh
python3 tools/test-i386-native-kernel-boot.py IMAGE EMITTED_KERNEL --out BOOT
```

The current candidate also passes isolated normal8MiB startup in54.512s
(module-zero-startup-8m-v1), with live WinMgr, exact welcome/42 pixels and
unchanged input pins. This is the existing60-second baseline subgate only.

Generation reproducibility can explicitly declare `--allow-kernel-build-date`
in `tools/test-i386-native-generations.py` or `tools/audit-i386-generations.py`.
The default still requires exact bytes. The opt-in locates the unique exported
Kernel date, requires positive/increasing dates and the corresponding exact
flat-image value, and normalizes only those eight bytes in each artifact.
All other module/flat bytes remain exact. Each actual installed boot area is
verified independently, including checksum/padding; normalized boot areas must
then match, allowing only the date and its derived checksum to differ.

`python3 tools/test-i386-generation-dates.py` passes five focused checks.
`build/generation-date-audit-v1/result.json` also exercises the CLI with the two
real native Kernel modules and derived flat-image fixtures: strict comparison
rejects their dates, declared comparison passes, and corrupted boot metadata
or a changed resident-provider byte rejects. These are comparator fixtures with
cross-built resident providers, not completed native generations.

The self-host installer now also rebuilds the delivered temporary
`CompilerProgramRuntimeProbe` module, alongside the six flat-kernel modules
and nine previously rebuilt providers. Previously that diagnostic module could
remain cross-built while generation comparison included its unchanged bytes.
The installer records its native origin and SHA-256; the generation runner
requires all three complete module sets before accepting an installed result.

`build/module-zero-native-auxiliary-v1/result.json` verifies the actual public
native build of that probe at64MiB:393055 bytes, all98 named function/data
exports match the cross reference, exact fresh42 pixels, unchanged prior file
tree and unchanged inputs. The probe's diagnostic vectors have not been run by
this build test. Installation and complete native generations remain separate
required gates; the nine-provider native build is still in progress.

The emitted native program probe also executes successfully in diagnostic boot
at16MiB (`module-zero-native-auxiliary-diagnostic-v1`). Only that module is
replaced in a disposable image with the existing diagnostic flag enabled.
Both program-probe phases complete exactly once, then normal source startup,
exact welcome/command pixels and fresh42 pass. The diagnostic image and all
inputs remain unchanged. This is functional evidence with other cross-built
modules, not a native generation or isolated timing profile.

ConsoleRuntime is the first completed provider in the nine-provider build.
The observed2747254-byte module has all1625 named exports matching the cross
reference (1421 functions,204 data). `module-zero-console-native-install-v1`
installs those exact bytes through guest FileDel/FileMove, then boots them
separately at8MiB with a live WinMgr. Arithmetic42, DocAllocationCheck13,
exact final42 pixels, and one diagnostic load/growth-recovery/unload pass.
The preserved candidate differs from the canonical file tree only at the
ConsoleRuntime module. The writable boot copy preserves every prior file and
adds only the check's expected `/AllocRead.DD`, containing `read` plus byte05.
It is not raw-byte unchanged; the source and preserved candidate are unchanged.

The native console/probe executable ranges also pass the existing386 allowlist
(`module-zero-native-components-instruction-v1`), among otherwise cross-built
modules. The other eight native providers and complete installed generations
remain pending. Inventory remains2/686; full C1-C5 remain open.

CompilerRuntime is now also emitted natively:1342360 bytes and539 named
exports. Compared with the cross reference, the host assembly's two division
boundary labels are replaced by the native I386DivTemplate data export. Its
185 bytes exactly match DivideTemplate.HC; all other named export kinds match.
`module-zero-native-compiler-instruction-v1` passes the existing386 executable
allowlist and native division-template data/range checks.

`module-zero-console-compiler-native-install-v1` installs the emitted compiler
and console through the guest filesystem APIs, then separately boots at8MiB.
Normal source startup, arithmetic42, DocAllocationCheck13, exact final42 pixels
and one diagnostic load/growth-recovery/unload pass. Both exact native module
payloads are verified; every other prior file stays unchanged. The boot copy
adds only expected AllocRead.DD (`read` plus05), while the source and preserved
candidate hashes remain exact. The full provider job continues at CompilerProbe;
these two installed native providers do not qualify a complete native generation.

The installed native compiler successfully rebuilds Startup at64MiB
(`module-zero-native-compiler-startup-v1`):391 bytes, the expected export
contract, one build-provider load and exact fresh42 pixels. The persisted
module and full prior file tree are independently checked, with unchanged
source/helper/input pins. This exercises a build through the emitted native
compiler, not merely compilation using the preceding cross-built compiler.
It remains a single-provider rebuild with other cross-built components.

`module-zero-native-compiler-probes-diagnostic-v1` additionally replaces both
temporary compiler probes with their emitted native modules on the paired
native compiler/console image. Diagnostic boot at16MiB completes both program
phases exactly once, then normal source startup and exact welcome/42 pixels.
Only the intended two probe files change in the fixture; the diagnostic image
and input pins remain unchanged. Timing with concurrent jobs is not a profile.

The original provider job has also emitted CompilerProbe (567026 bytes,137
matching named exports) and FileRuntime (295839 bytes,158 matching named
exports). Their complete installation is still pending, as are MemoryRuntime,
BuildRuntime, EditorRuntime, DocDiagnosticRuntime and Startup in that job.
Both complete native generations and full C1-C5 qualification remain open.
