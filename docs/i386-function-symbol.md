# Public function symbols and debug ranges

Psalmody's JukePuppet accesses `CHashFun.dbg_info` and then walks another task's
callers. Native public headers originally exposed only a forward declaration
of CHashFun. Loading the complete existing SymbolTypes.HH permits member access
but reaches the separate missing TaskCaller service.

`tools/test-i386-function-symbol.py` compiles a two-argument function with a
default value, finds its actual symbol, and checks its function kind, name,
argument count, return type, executable address and default-argument execution
(mask 63). It also requires a generated debug record with ordered source bounds,
a nonzero start address and an end after the start. The expected vector is
`63,1,1,1,1,4`; it preserves the original 32-bit debug-address entry convention.

* `build/i386-function-symbol-original-v2/result.json`: the exact vector passes
  on the pinned original; inputs unchanged.
* `build/i386-function-symbol-native-v1/result.json`: the interface-220 image
  rejects member access through incomplete CHashFun at fixture line 12; inputs
  unchanged.
* `build/i386-function-symbol-shared-types-v1/result.json`: explicitly including
  complete shared symbol types allows every symbol-field check to pass, but the
  vector is `63,0,0,0,0,4`. The test correctly fails because debug metadata is
  absent; inputs unchanged.

```
python3 tools/test-i386-function-symbol.py --out build/function-symbol-original
python3 tools/test-i386-function-symbol.py build/IMAGE/kernel.img --out build/function-symbol-native
# Diagnostic only: separate type visibility from emitted metadata.
python3 tools/test-i386-function-symbol.py build/IMAGE/kernel.img --shared-types --out build/function-symbol-types
```

The first header candidate included SymbolTypes.HH from PublicHash.HH in the
second root-header transaction. Its bootstrap and cross-build passed, but normal
startup rejected publication of the root user headers with no parser error,
then halted (`build/i386-function-symbol-public-v1/result.json`). The 8 MiB
welcome test also failed at that same startup. This is not an API behavior pass.
The next candidate moves the include before PublicTaskTypes in the initial
kernel-header transaction, so complete function types precede the task records
which refer to them. That candidate also rejects atomic publication in the
first kernel-header transaction (`build/i386-function-symbol-public-v2`),
with unchanged test inputs. Its cross-build and all 1,714 source/tool pins
passed before follow-up edits. Moving the include alone is insufficient.

A source-only diagnostic removes the redundant CAOTImportExport forward
declaration from SymbolTypes.HH: DefineTypes.HH already declares it. The atomic
publisher explicitly rejects duplicate names within one transaction, whereas
ordinary interactive declarations permit shadowing. The diagnostic preserves
all other file bytes, attributes and dates (`build/i386-public-symbol-types-dedup-v1/source-audit.json`).
Normal 64 MiB KVM startup now succeeds and the fixture compiles without the
explicit shared-types workaround. `build/i386-function-symbol-dedup-v1/result.json`
reaches the expected remaining failure: `63,0,0,0,0,4`, with unchanged inputs.
All six symbol-field checks pass; generated debug metadata remains absent.
The 8 MiB welcome/clear/input check and clean bootstrap rebuild are in progress.
The diagnostic uses unchanged cross-v2 compiled providers and one source-header
edit; it is not yet clean-rebuild qualification of the header fix.

`I386FrontendFunctionCode` currently returns a null debug pointer explicitly.
Restoring debug metadata requires actual emitter source-line offsets and proper
allocation ownership, publication, extern completion and failure cleanup. The
full regression remains red until real generated records exist; placeholder
ranges or omitting the metadata assertion would not qualify it. Complete line
mapping, task stack inspection, module debug interchange and Psalmody/C1–C5
qualification remain open.
