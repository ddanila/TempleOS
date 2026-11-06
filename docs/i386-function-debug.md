# Generated function debug records

The original function-symbol oracle exposed a null `CHashFun.dbg_info` in the
native frontend. The candidate now records the first final-pass output offset
for each intermediate-code source line. Unmapped lines remain zero. Offsets
are relocated to the allocated function code, with the original first-address
and end-address entries and 32-bit address storage. The end includes the
function's literal/data area, matching the original range convention.

The line table belongs to the parser allocation journal until symbol
publication. The existing symbol ownership walk transfers or releases it.
Extern completion validates the allocation, size, bounds and association with
its compiled output before copying the debug pointer to the existing public
function identity. Ordinary publication uses the same validation. This does
not add debug interchange to the T32M format or implement TaskCaller.

`tools/test-i386-function-debug.py` uses actual `Caller` return addresses from
two separate lines of a compiled function. Each must fall within its mapped
line range, and the two line entries must be nonzero and strictly different.
It also completes an extern through ExePutS and checks stable descriptor
identity, a debug start matching its executable address, and execution returning
42. The expected eight-element vector is all ones. Absolute machine addresses
are not compared across architectures.

The original fixture is included as its own file so line numbers match the
native include. The initial two original attempts concatenated a startup line
before the fixture, shifting its line numbers; those failed controls and raw
line/PC captures remain preserved. This was corrected in the harness, without
changing the source-line range checks.

* `build/i386-function-debug-original-v4/result.json`: original eight-element
  vector passes with unchanged inputs.
* `build/i386-function-debug-native-v3/result.json`: all eight checks pass
  on candidate cross-v2, including strict distinct-line entries; inputs unchanged.
* `build/i386-function-symbol-debug-v1/result.json`: the original public symbol
  and nonempty debug-range vector `63,1,1,1,1,4` passes natively.
* `build/i386-function-debug-cross-v1/main-source-audit.json`: all 1,714 recorded
  bootstrap inputs match before subsequent diagnostic-probe edits. Both
  bootstrap generations and the native cross-build pass.

The first diagnostic run stops at an outdated public-header warning count:
the complete CHashClass/CHashFun records introduce two additional unused-forward
warnings. The probe update retains an exact count and additionally checks the
published function size and inherited dbg_info member offset. The corrected
16 MiB TCG 486 diagnostic run passes (`build/i386-function-debug-minimal-v2/terminal-audit.json`):
22 publication cases, 28 program cases, 28 completion cases, header rollback and
code-heap lifetime checks in both phases, exact warning identities and all
307,200 welcome pixels. The diagnostic disk is unchanged. This is not the
complete builder --test suite or the 60-second interactive timing gate.

The candidate also passes exact welcome pixels and suspended clear/input at
8 MiB TCG 486,-fpu (`build/i386-function-debug-welcome-v1/result.json`).
Partial-declaration recovery passes at 8 MiB
KVM 486,-fpu (`build/i386-function-debug-partial-v1/result.json`), with unchanged
inputs, across both ExePutS modes and all eight recovery cases. Cross-v2 changes
only CompilerProbe.t32m relative to cross-v1; all other retained modules are
byte-identical, and all 1,714 source pins match.
The equivalent host warning-identity expectation in tools/build-i386-kernel.py
still needs the same update. That file is pinned by the live second-generation
native build, so it remains unchanged until that run terminates. The exact edit
is saved in `build/i386-function-debug-minimal-v2/pending-host-checker.patch`;
apply it and verify the checker after the terminal input audit. Until then,
the builder's full --test checker will reject the new warning identities even
though the independent diagnostic audit above passes.

Complete source mapping (including optimized branches and assembly), metadata
failure injection, TaskCaller, Psalmody and C1–C5 remain unqualified.

```
python3 tools/test-i386-function-debug.py --out OUT_ORIGINAL
python3 tools/test-i386-function-debug.py IMAGE --out OUT_NATIVE
python3 tools/test-i386-function-symbol.py IMAGE --out OUT_SYMBOLS
```
