# Native module default-string ownership

Native module commands clear CCF_AOT_COMPILE while parsing declarations, but
retain CCF_MODULE_SOURCE. The shared default-argument parser previously copied
string and lastclass defaults only for AOT mode. It therefore emitted addresses
of compiler-owned strings into native module code. The parser now treats both
modes as requiring module-owned string data; ordinary JIT calls retain their
existing behavior.

The two-generation ConsoleRuntime mismatch first exposed this in two implicit
DocForm class arguments. The focused baseline in
`build/i386-module-default-strings-baseline-v1` builds a class-name default and
an explicit string default twice, holding a 64 KiB allocation between builds.
Both strings are absent from module data, and six bytes differ in the two
callers. The original checker's data-range field mistake is preserved with its
runner; `corrected-range-audit.json` independently confirms both failures using
the actual range-length field. Baseline execution also returns a controlled
failure in `build/i386-module-default-strings-baseline-execution-v1`.

`build/i386-module-default-strings-native-v1/result.json` passes with unchanged
inputs: both strings are module-owned and both builds are byte-identical. The
test links the actual emitted i386 code into an ELF at two distinct addresses,
resolves only internal calls, and checks four returned pointers and string
contents. This proves the pure fixture's relocation behavior, not the native OS
loader or complete provider-generation equivalence.

Both bootstrap generations and cross-v1 pass; its source/helper audit is
unchanged. The 8 MiB TCG welcome/clear/input regression passes with unchanged
inputs in `build/i386-module-default-strings-welcome-v1`. The full nine-module
native generation passes in `build/i386-default-strings-native-nine-v1`, using
the frozen full-content interface-224 candidate at 64 MiB KVM `486,-fpu` with
paced keyboard commands and live WinMgr. The build provider loads once, all nine
persisted modules have the expected export sets, and the concluding arithmetic
interaction passes. This qualifies generation one, not two-generation equality.

`terminal-audit.json` verifies the persisted module hashes and every original
input pin except the explicitly disclosed on-disk builder helper. Its preloaded
helper snapshot matches the original pin, its disk-reader AST matches the
current helper, and its runner snapshot matches the pinned runner. Extracted
modules are retained under `exports/`. The generation predates the later public
control and probe-size changes; it does not qualify those newer sources.

Installation is running in `build/i386-default-strings-native-install-v1`, using
a fresh copy and preserving the generation-one source image. Installation,
second-generation comparison, required memory profiles and C5 remain open.
