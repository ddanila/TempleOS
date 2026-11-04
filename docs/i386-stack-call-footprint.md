# Short ESP operands and call normalization footprint

The native backend used a disp32 ESP operand for every call-argument load/store
and every indirect call, including offset zero and small positive offsets.
`I386EspMemory` in `Compiler/I386/EmitCore.HC` now emits the same operand with
no displacement at zero, a sign-extended disp8 at -128 through 127, and disp32
otherwise. ESP retains its required no-index SIB byte. Measuring and emitting
use the same helper, so labels, fixups and planned output sizes agree.

For supported arguments smaller than eight bytes, `I386Normalize` defines EDX
from EAX: signed types sign-extend, unsigned types and pointers zero-extend.
The backend therefore omits the incoming high-word load. It still stores both
normalized words into the existing eight-byte argument slot. Eight-byte values,
argument order, slot widths, cleanup, return behavior and public ABI are retained.
No RAM limit, allocator reserve, display ownership or application body changes.

The final candidate is `build/i386-esp-displacement-cross-v2/kernel.img`.
`build/i386-esp-displacement-cross-v2/footprint.json` compares actual module code
sizes with the preceding popup-cross-v3 image:

| Module | Reduction in bytes |
| --- | ---: |
| Kernel | 30,576 |
| ConsoleRuntime | 171,336 |
| CompilerRuntime | 143,984 |
| FileRuntime | 22,808 |
| MemoryRuntime | 14,408 |
| Total of these five modules | 383,112 |

The export retention report checks all 16 module export sets: no export is
removed or added. The 386 instruction audit and the 1,361-file delivered
Kernel/Compiler/Adam/Doc source audit pass. Two successive **original** compiler/
kernel rebuild generations pass (`build/esp-displacement-rebuild-v3.log`);
these remain bootstrap evidence, not the C5 native rebuild gate.

## Regression evidence

- `build/i386-esp-displacement-reference-v5/result.json`: the exact production
  emitter runs on the pinned original OS. All 153 encoding cases match the host
  oracle, sizing agrees with emission, and register index eight is rejected
  before writing. Cases include zero, 1, 127, 128, -129, -128, -1 and both signed
  32-bit extremes; MOV load/store covers all eight register fields, indirect
  CALL covers its actual /2 field. This byte test does not execute its operands.
- `build/i386-esp-function-evidence-v1/result.json`: all 249 existing function
  corpus cases, including five expected faults, pass in two native 8 MiB 486
  runners with instruction auditing. The adjacent provenance file records the
  completed corpus and source identities.
- `build/i386-stack-call-reference-v3/result.json` and
  `build/i386-stack-call-native-v2/result.json`: the same real source returns
  mask 63 on the pinned original and final 8 MiB KVM 486 without FPU. It covers
  direct, indirect and nested calls with 17 narrow/pointer arguments, signed and
  unsigned truncation, argument offsets beyond +127, a zero-argument indirect
  call, variadic fixed-argument normalization with full 64-bit argv, and a
  256-byte frame canary. Native includes exact result/42 pixel checks, persisted
  fixture identity and an offline filesystem audit. All input pins stay unchanged.

The final physical census is `build/i386-heap-pressure-esp-v2/result.json`.
The real canonical `/Kernel/SymbolTypes.HH` request now succeeds at 8 MiB.

| Main arena / phase | Capacity | Used spans | Free spans | Largest free payload |
| --- | ---: | ---: | ---: | ---: |
| Preceding image / startup | 6,649,344 | 6,618,872 | 30,472 | 8,952 |
| Final candidate / startup | 6,679,552 | 6,268,152 | 411,400 | 389,880 |
| Final candidate / header loaded | 6,679,552 | 6,342,816 | 336,736 | 319,336 |

All sizes are bytes. Spans include raw allocator headers; largest free payload
excludes its header. Main-arena startup allocation count remains 14,216. The
fallback arena remains 551,936 bytes with 8,272 free. Both full physical arena
chains validate before and after the request, and input pins remain unchanged.
Capacity increases because the resident kernel becomes smaller; physical RAM
stays 8 MiB. No pressure is hidden by relabeling a larger guest.

The intermediate displacement-only image passed header loading and the native
call contract, but its 8 MiB servant fixture compilation still recorded OutMem
(`build/i386-default-servant-esp-8-v1/result.json`); this is not a servant pass.
The later removal of the dead high-word load is included in the final candidate.
Full minimal-profile, whole-application, desktop and C1-C5 gates remain open.

The final 8 MiB default-servant attempt
(`build/i386-default-servant-esp-8-v2/result.json`) passes symbol-header and
fixture loading and enters the real `JRContract`. It then records
`PARSER CODE ALLOCATION REJECT C:/Doc/EdPullDown.DD`, followed by unhandled
OutMem during the actual startup hook. The servant contract remains **fail**;
progress past its previous setup failures is not service qualification.

The separate normal-startup smoke (`build/i386-esp-minimal8-v1/budget.json`)
passes in 41.004867 seconds against the unchanged 60-second limit, with live
WinMgr/welcome and exact arithmetic/public-input-state pixel checks. Its input
provenance remains unchanged. This is not the complete minimal regression suite.

The final 64 MiB popup regression
(`build/i386-autocomplete-popup-esp-v1/result.json`) passes against the existing
original reference: the complete Apple definition, matching document/geometry,
open/PageUp/PageDown, all 665,664 mutually visible static pixels, actual Escape
child retirement, restored parent roles/focus/input, resumed completion and
execution, persisted reports and offline filesystem audit. The existing
visibility/caret exclusions are retained, and all input pins remain unchanged.

The full default-servant contract remains passing at the explicitly selected
64 MiB profile (`build/i386-default-servant-esp-64-v1/result.json`): seven pixel
checkpoints, real default startup interposition once after inhibit initialization,
constructor roles, ten task dispatch/results, title/idle/ring checks, restored
hook and resumed input, exact persisted fixture and offline filesystem audit.
This does not supersede the final 8 MiB failure.

To rerun the new checks, use fresh output directories:

```
python3 tools/test-i386-esp-displacement.py --out build/esp-encoding-new
python3 tools/test-i386-stack-call.py --original --out build/esp-calls-original-new
python3 tools/test-i386-stack-call.py IMAGE --out build/esp-calls-native-new
```

The native call runner selects KVM, 486 without FPU and 8 MiB explicitly;
the original runner uses the pinned x64 reference. Output artifacts preserve
input hashes and result scope. Run the heap census separately with
`tools/observe-i386-heap-pressure.py IMAGE --out FRESH_DIRECTORY`.
