# Bounded-memory self-hosting goal

Deliver reliable 386/VGA boot and native rebuilding while preserving HolyC,
DolDoc, existing stack limits, public APIs, and ownership/unwind behavior.

Acceptance requires current-source evidence for:

1. Normal startup at 8 MiB, retained function/static state, and VGA restoration.
2. Complete native HolyC/DolDoc provider builds at 16 MiB.
3. Two successive self-hosted generations and successful installation/boot,
   with reproducibility checks at the scope supported by the build manifests.
4. Publication, software floating-point, saved assembly, optimizer and backend
   regression checks on QEMU without an FPU.
5. Selective diagnostics restored and the verified configuration documented.

## Current experiment — optimizer scratch prefix

The failed baseline is `build/i386-output-phase-boot-v69-8m/result.json`.
It rejects a 4,096-byte allocation; the exact caller remains unproven.
`OptPass012Core` accesses the first stack and resets `ptr2`; it does not access
`stk2`. The private frontend optimizer now requests storage through `ptr2`
(2,056 bytes), while the public optimizer continues to allocate and retain a
complete 4,096-byte `CPrsStk`. Borrowed stacks keep the original contract.
The first stack still has all 255 I64 slots. Exceptions retain control ownership.
Normal output-phase logging is selective again.

The optimizer-prefix candidate passed two-generation bootstrap, native cross-build,
386 audit, and the 16 MiB diagnostic suite (50 publication cases and nine
runtime/VGA commands). Evidence is under `build/i386-optimizer-prefix-*`.
Normal 8 MiB startup still fails: request 4,116 bytes, used `0x65B1F0`, heap
`0x65C200`, largest block `0xF60`. No boot recovery or full-build recovery is proven.

## Next experiment — ordinary ownership record prefix

Ordinary parser allocations now omit `requested`, which is accessed only for
records with a non-null executable-buffer owner. Executable records retain the
full layout; all records retain next/last, payload and owner fields. This saves
eight arena bytes per ordinary record on i386, without changing payload sizes.
The parser memory probe adds 64 live 37-byte allocations with a 5,632-byte total
budget, distinct endpoint contents, reverse release, and exact heap restoration.
Existing failure/unwind probes remain. Bootstrap and native qualification are
required before claiming this candidate passes; evidence will use the
`i386-parser-record-prefix` build prefix.

## Current results — ordinary ownership record prefix

`build/i386-parser-record-prefix-cross` passes two-generation bootstrap and the
386 instruction audit. `build/i386-parser-record-prefix-boot-8m/result.json`
passes normal startup in 58.93 seconds, all nine retained-code/static and VGA
commands, and the interactive startup budget on `486,-fpu`.
`build/i386-parser-record-prefix-float-16m/result.json` passes all 16 runtime
integer/F64 commands. Full 16 MiB diagnostics pass all 50 publication cases and nine runtime/VGA
commands. `memory-contract-check.json` verifies optimizer, new parser-memory
budget, emitter and backend markers in both phases.
`build/i386-parser-record-prefix-float-8m/result.json` passes 16 runtime
integer/F64 commands; `build/i386-parser-record-prefix-bare-8m/result.json`
passes 13 saved-source/AOT assembly commands and interrupt-state restoration.

The six-provider native rebuild remains running at 16 MiB under TCG on
`486,-fpu`, in `build/i386-parser-record-prefix-retained-16m`. Its current
process must be checked before resuming or restarting. Neither full rebuilding
nor successive native generations/install acceptance follows from the passes
above. The build was launched with:

```sh
python3 tools/test-i386-retained-build.py \
  --disk build/i386-parser-record-prefix-cross/kernel.img \
  --out build/i386-parser-record-prefix-retained-16m \
  --reference-exports build/i386-parser-record-prefix-cross/exports \
  --accel tcg --cpu 486,-fpu --qmp-stdio --command-timeout 14400
```

The native-build harness now opts into detection of complete `BUILD MODULE
REJECT` lines since the current command began, avoiding hours of waiting after a
terminal guest failure. It records running/failure state and disk hashes.
`python3 tools/test-i386-command-rejection.py` passes three host tests covering
current rejection, stale/partial output, and opt-in/line-boundary behavior.

## Continuing native qualification

The retained rebuild is still live and compiling ConsoleRuntime/DolDoc. An older
bare-assembly build process was found still waiting after its already recorded
OutMem rejection; it was stopped after checking its exact PID, command line,
and rejection log. Its evidence remains in
`build/i386-bare-assembly-full-build-oom-v69/stopped-live-process.json`.

A separate development run in `build/i386-parser-record-prefix-flat-development`
compiles the six flat-kernel components and exercises installation/8 MiB boot
using the cross-built retained runtime. This can expose kernel/installer defects
early but **does not count as full self-hosting**. Both runs use `486,-fpu`, TCG,
and 16 MiB for native compilation. Check live processes before restarting either.

After the six retained providers pass, run the complete qualification:

```sh
python3 tools/test-i386-native-generations.py \
  --repository . \
  --retained-build build/i386-parser-record-prefix-retained-16m \
  --stage-listing build/i386-parser-record-prefix-cross/kernel-stage.lst \
  --out build/i386-parser-record-prefix-generations \
  --accel tcg --cpu 486,-fpu --qmp-stdio --build-command-timeout 14400
```

This runner requires all six guest-built providers, installs and boots them,
builds/installs the flat kernel, repeats with the resulting guest runtime,
and compares all twelve modules, linked kernel and installed boot area.
The command timeout now propagates to flat builds as well as retained builds.
Flat builds opt into explicit module-rejection detection too. Python syntax
checks and the three rejection-log regression tests pass for these harness changes;
the ongoing native tests remain the required end-to-end evidence.
