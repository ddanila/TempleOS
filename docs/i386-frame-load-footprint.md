# Native frame-load footprint

The native backend now folds an already validated pointer-valued
RBP/constant/add tree followed immediately by a matching dereference into an
EBP-relative load. It retains the existing normalization, EDX:EAX result,
evaluation-stack depth, flags and high-word-before-low-word read order. The
matcher checks operand links, resolved pointer/value classes, supported widths,
function descriptor tags, flags and logical boundaries without changing IR
links. Only PUSH_RES/BY_VAL load flags are accepted; other cases retain the
existing path. Scratch ECX/EBX contents are not an instruction-level contract.

The shared EBP memory emitter selects signed disp8 or disp32, including the
required explicit zero displacement. RAM, allocator policy, worker arena size,
display buffers and application source are unchanged.

## Footprint and runtime evidence

`build/i386-frame-load-full-v1/footprint.json` compares the five resident module
payloads with the preceding backing-accounting candidate:

| Module | Bytes removed |
| --- | ---: |
| Kernel | 32,808 |
| ConsoleRuntime | 165,656 |
| CompilerRuntime | 98,800 |
| FileRuntime | 21,728 |
| MemoryRuntime | 16,400 |
| Total | 335,392 |

All 16 module files are identical between the full-content candidate and the
minimal full-gate build; export names are unchanged. The full image is
`build/i386-frame-load-full-v1/kernel.img`, SHA-256
`73976ba8dce292472b7e0d17dbda3a2882c590f4ea2bd4deb2301a3b0a2878af`.

Verified checks:

- Two original bootstrap rebuild generations (`build/frame-load-rebuild-v3.log`),
  386 instruction audits and the delivered-source audit (1,361 files).
- Exact production emitter/matcher execution on the original OS:
  `build/i386-frame-load-encoding-reference-v3/result.json`, 468 encodings,
  measure/write agreement, invalid-register rejection and both guard masks 1023.
  The cases include signed displacement boundaries, wrapping high-word offsets,
  all supported load types, flags, function descriptors and logical boundaries.
- All 249 native function cases and five expected faults on an 8 MiB 486 runner:
  `build/i386-frame-load-function-evidence-v2/result.json`.
- Paired original/native call and frame contracts return masks 63/255:
  `build/i386-frame-load-runtime-reference-v2/result.json` and
  `build/i386-frame-load-runtime-native-v1/result.json`. These include 17 arguments,
  direct/indirect/nested/variadic calls, local arrays, pointer aliases and F64.
- All three portable heap-source runners pass; preserved results and provenance
  are in `build/i386-frame-load-heap-evidence-v1`.
- The actual default-servant startup contract passes at 8 MiB under KVM and TCG:
  `build/i386-default-servant-frame-load-8-v1/result.json` and
  `build/i386-default-servant-frame-load-8-tcg-v1/result.json`. The source-identical
  preload path checks ten dispatch/results, roles, title/idle/rings, restored
  hook, seven pixel checkpoints and filesystem integrity. TCG startup takes
  73.89 seconds; this is a functional pass, not a 60-second TCG timing pass.
- The 64 MiB Apple popup differential passes all 665,664 compared visible static
  pixels, complete definition text, paging, Escape close, restored roles/input,
  resumed execution and filesystem checks:
  `build/i386-autocomplete-popup-frame-load-v1/result.json`.

The independent normal 8 MiB KVM startup smoke passes in 34.03 seconds under its
unchanged 60-second limit (`build/i386-frame-load-smoke8-v1/budget.json`).

The physical census (`build/i386-heap-pressure-frame-load-v1/result.json`)
validates both arenas and accepts the actual canonical symbol header. Main-arena
capacity is 6,800,896 bytes. Startup free spans total 1,664,504 bytes with largest
free payload 1,642,832; after header loading these are 1,588,808 and 1,571,888.
These normal-startup measurements do not describe the diagnostic worker's heap.

## Remaining full gate

The unchanged default 8 MiB `build-i386-kernel.py --test` run in
`build/i386-frame-load-minimal-gate-v2` completes the root compiler/program/header
suite. Worker creation now succeeds and its memory probe starts. After the
intentional handled 16 MiB rejection and successful hash/define checks, the
worker's `MemoryProbe` cannot satisfy `MemoryCAlloc(131000,task->code_heap)` and
ends with unhandled OutMem. Its isolated public probe pool obtains backing from
the kernel physical heap; the worker's private arena size is unchanged. No
precise physical free-space census was captured at this failing request.

`failure.json` pins the images, terminal log and relevant production sources.
The allocation and gate are not reduced or bypassed. Later worker checks, full
minimal regressions, all 686 inventory qualifications and C1-C5 remain open.
The two original rebuild generations above do not satisfy C5's native rebuilds.
