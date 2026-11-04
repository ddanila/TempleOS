# Frame-address emission and the 8 MiB servant contract

The backend previously materialized a local address by pushing the frame
pointer and a wide constant, popping both values, adding them, normalizing the
pointer and pushing it again. `I386FrameAddressEnd` recognizes only the complete
adjacent `IC_RBP`, `IC_IMM_I64`, `IC_ADD` tree with the same resolved pointer
class on all three nodes and no flags. It rejects mismatched operand links and
logical-control boundaries inside the sequence. All other IR follows the
existing path; the matcher does not edit IR or allocate storage.

The matched path emits `LEA EAX,[EBP+disp]`, followed by the same zero-high-word
XOR and two result pushes. Pointer normalization already discards the wide
carry, so the 32-bit LEA preserves the result modulo 2^32. Evaluation stack depth,
EAX/EDX value and final arithmetic flags are retained. Backend scratch-register
contents are not an inter-instruction language contract. A logical boundary on
the final add is processed normally after the fused emission. EBP uses disp8
including explicit zero, or disp32 outside the signed-byte range. Both sizing
and emission use the same helper.

The final full-content image is `build/i386-frame-address-cross-v2/kernel.img`.
Compared with the preceding esp-displacement-cross-v2 image, actual module
payload reductions are:

| Module | Reduction in bytes |
| --- | ---: |
| Kernel | 88,552 |
| ConsoleRuntime | 473,192 |
| CompilerRuntime | 257,776 |
| FileRuntime | 63,168 |
| MemoryRuntime | 44,824 |
| Total of these five resident modules | 927,512 |

`footprint.json` in the build directory records all 16 modules and their hashes.
The 386 instruction audit, unchanged export sets across all 16 modules and
1,361-file delivered Kernel/Compiler/Adam/Doc source audit pass. Two successive
original compiler/kernel rebuild generations pass
(`build/frame-address-rebuild-v2.log`). These are bootstrap rebuilds, not the C5
native rebuild/install/boot qualification gate.

## Verified behavior

- `build/i386-frame-encoding-reference-v2/result.json` runs the exact production
  emitters and matcher on the pinned original OS: 153 ESP encodings, nine EBP
  displacement cases, matching measure/write lengths, rejection of an invalid
  register before output, and frame-guard mask 1023. Guards cover null/truncated
  sequences, wrong opcodes, flags on each node, mismatched operand links,
  differing/missing/non-pointer types, internal logical boundaries and an
  allowed boundary on the final add. The original tree links remain unchanged.
- `build/i386-frame-function-evidence-v1/result.json`: all 249 existing function
  cases and five expected faults pass on a native 8 MiB 486 runner, with
  instruction auditing and preserved corpus/source provenance.
- `build/i386-frame-runtime-reference-v4/result.json` and
  `build/i386-frame-runtime-native-v1/result.json`: the same source returns 63
  for the existing 17-argument direct/indirect/nested/variadic call contract and
  255 for the added frame contract. The latter checks a 1,024-byte local array,
  negative/large local offsets, aliased local pointers with explicit mutation,
  pointer logical boundaries, and an addressed F64 local. Its floating check
  combines exact stored 3.75 bits with a tolerance for the original x87 constant
  comparison. Native runs at 8 MiB, KVM 486 without FPU, with exact result/42 pixel
  checks, persisted fixture identity and a final offline filesystem audit.
- `build/i386-default-servant-frame-8-v1/result.json`: the actual 8 MiB KVM
  default-startup contract passes. It includes symbol-header and source-identical
  fixture loading, actual default hook interposition exactly once after inhibit
  initialization, constructor document/menu roles, ten dispatch/results, title/
  idle/ring checks, restored hook and resumed input, seven pixel checkpoints,
  exact persisted fixture and final filesystem audit. Earlier header, fixture
  compilation and EdPullDown.DD OutMem attempts remain recorded as failures;
  the passing run does not replace those artifacts. Fixture preload and KVM are
  explicit options; the legacy keyboard-transfer path remains available.

All listed successful runs retain unchanged input pins. The separate startup
smoke `build/i386-frame-minimal8-v1/budget.json` passes in 36.252075 seconds under
the unchanged 60-second limit, with welcome/live WinMgr and arithmetic/public
input-state pixels. It is not the complete minimal regression suite.

The physical census `build/i386-heap-pressure-frame-v1/result.json` validates
both full arena chains before and after the real canonical symbol-header load:

| Main arena / phase | Capacity | Used spans | Free spans | Largest free payload |
| --- | ---: | ---: | ---: | ---: |
| Preceding image / startup | 6,679,552 | 6,268,152 | 411,400 | 389,880 |
| Frame candidate / startup | 6,768,128 | 5,427,000 | 1,341,128 | 1,319,672 |
| Frame candidate / header loaded | 6,768,128 | 5,501,600 | 1,266,528 | 1,249,128 |

Sizes are bytes; spans include raw headers, largest payload excludes its header.
Physical RAM stays 8 MiB. Kernel shrinkage increases the available main arena;
allocator reserves, rounding, display ownership, application source and workload
are unchanged.

## Remaining gates

The unchanged complete `build-i386-kernel.py --test` command was run at its
8 MiB diagnostic default in `build/i386-frame-address-minimal-gate-v1`. It stops
in public-header probe phase zero: direct PublicKernel.HH inclusion reaches
PublicDebug.HH's `throw(...,Bool no_log=FALSE)` without a FALSE definition.
`boot/debug.log`, the command log and `failure.json` record the terminal failure.
The preceding commit has the same header dependency; normal user startup
supplies the constants through PublicUser.HH. No header/probe assertion is
removed or bypassed here. This full gate remains **fail** and needs a separate
header dependency fix and rerun.

The global unhandled-exception policy is also unchanged; fixing the successful
servant's physical headroom does not qualify allocation-failure recovery. Full
minimal regressions, all application workflows, the complete desktop and C1-C5
remain open.

The same source-identical preload servant contract also passes at 8 MiB under
TCG (`build/i386-default-servant-frame-8-tcg-v1/result.json`), including the
seven pixel checkpoints and final filesystem audit. Its measured normal startup
is 76.912414 seconds: this is a functional service pass, **not** a 60-second TCG
timing pass. The separate 36.25-second timing result above uses KVM explicitly.
Legacy keyboard fixture transfer remains a separate path.

The final 64 MiB popup regression
(`build/i386-autocomplete-popup-frame-v1/result.json`) passes the complete Apple
definition, canonical documents/geometry and page rows, all 665,664 mutually
visible static pixels with the established caret/occlusion rules, actual Escape
child retirement, restored parent roles/focus/input, resumed completion and
execution, persisted reports and final filesystem audit. Inputs remained
unchanged throughout the run.
