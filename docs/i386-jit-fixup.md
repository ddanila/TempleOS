# Public JIT assembly fixups

Console 253 first bound `CmpFixUpJITAsm` through the explicit
`Kernel/I386/PublicLoader.HH` header. Its first call loads the shipping
`Compiler/I386/PublicJITSupport.HC` source into Adam's system symbol scope and
caches the complete implementation there. The facade subsequently calls that
implementation with the caller's ordinary public `CCmpCtrl` and `CAOT` layouts.
The system-owned functions outlive the invoking compiler control and task.
The export table retains its previous 670 entries and appends the function and
its internal publication context, for 672 entries total.

CMain and the system source service share `Compiler/JITFixupCore.HC`,
`CodeLabel.HC` and `LabelForwardCore.HC`. These contain the complete original
fixup, label search and forwarding algorithms. Scalar I64 patch addresses
preserve negative 64-bit relative values with 32-bit pointer storage. Deferred
resolution passes zero flags explicitly, and trace decoding selects 32 bits for
an i386 target. Source implementation-name macros are restored after the
system service is compiled.

The service is loaded through the normal Adam file path. The native contract
packages only its fixture and public-header include; its log must contain
exactly one system publication marker across repeated calls.

## Contract and ownership

`tools/test-i386-jit-fixup.py` compares the normal public binding with distinctly
named routines restored from the pinned original system. The native run requires
a passing original reference. Forty assertions cover:

- Absolute add/sub patches at 8, 16, 32 and 64 bits, with adjacent-byte guards.
- Relative/immediate exports at both export widths, source-link transfer and
  actual deferred-import resolution and invalidation.
- Forward/backward relative patches and immediate patches at all four widths;
  forwarded labels, use counts, function and global addresses.
- Missing references without writes, signed 8/16/32-bit boundary acceptance,
  six one-step overflow exceptions and caller ownership of first-failure packets.
- Successful packet consumption, real trace disassembly and exact caller-heap
  recovery after accounting for the retained trace text.

An independent six-exception `LexExcept` control measures diagnostic retention.
The original retains 288 bytes in both that control and the fixup range-error
phase. The normal native run retains zero in both. The cold system load also
leaves zero retained bytes in the caller's heap. The complete normalized trace
is 113 bytes and matches the original, including highlight commands, symbolic
addresses, XCHG spelling, spacing and RET. Only exact numeric instruction PCs
may be normalized; the observed traces are already symbolic.

The original's partial-progress exception policy remains unchanged: a failure
after earlier records have been consumed does not have a qualified unwind path.
The range tests deliberately fail on the first import record and clean up that
still-owned packet. First-use load failure/retry, cancellation and simultaneous
cold callers remain unqualified.

## Compiler scopes and emission memory

CompilerRuntime 95 accepts a borrowed hash-table prefix when its chain reaches
the task's validated owned symbol table. Detached heads and cycles are rejected.
Ownership signatures, task/heap identity, owner pins and the owned table itself
remain intact. Task cloning and symbol destruction retain their existing owned-
table requirements. The caller must keep borrowed tables alive for the control.

This is required by real trace output: DolDoc opens a nested compiler control to
parse `$$HL,1$$`. Previously its factory rejected the fixture's temporary caller
scope and reported OutMem before instruction decoding. Direct source-link and
fresh-document probes isolated that rejection.

After backend emission, `I386COCInstructionsRelease` releases current live IR
before allocating the persistent executable copy. It collects retired operands
only when the control has no live IR records anywhere; a saved parent graph
keeps its operands alive. Miscellaneous payloads, output bytes and relocation
records remain available to the linker. Interrupt masking is limited to each
release operation. The ordinary public graph discard policy is unchanged.
The standalone control fixture checks both scope rejection and nested graph
lifetime, including exact heap recovery.

## Decoder repair and startup footprint

Ui's old `(*_rip)(I64)` reinterpretation reads beyond a native four-byte pointer.
Scalar address differences now calculate padding lengths, and Un advances its
end pointer with ordinary byte-pointer arithmetic. Existing temporaries keep
Ui's local layout compact. The complete ModRM/SIB block is moved unchanged into
`UAsmModRM`, with the same decoded arguments and prefix state passed explicitly.
This bounds the largest decoder compilation graph while preserving its cases.

Earlier candidates still exhausted code allocation during 8 MiB startup.
Caller tracing maps that path to `I386FrontendOutput` reserving its executable
copy. The pre-split Ui grew from 0x60B0 to 0x60B8 bytes with the repair; both had
capacity 0x61E8, so a new allocation bucket was not the explanation. Repacked
unchanged-decoder and original-image controls pass. The ModRM split restores
8 MiB startup and prompt construction on the final candidate.
Allocation diagnostics now distinguish code-buffer and tracking-record failure.

## Evidence and limits

The JIT delivery checkpoint uses `build/i386-jit-fixup-cross-v9`. Its audit checks all
1,773 OS source hashes and 26 build-driver inputs. Passing evidence includes:

- `build/rebuild-test/result.json`: two x86-64 compiler/kernel rebuild generations
  with the shared implementation and final decoder; log `jit-modrm-bootstrap-v11`.
- `build/i386-jit-fixup-original-v7/result.json` and
  `build/i386-jit-fixup-native-v6/result.json`: all 40 assertions, exact trace,
  independent heap controls, native arithmetic pixels and packaged-volume audit.
  `build/i386-jit-shared-x64-v1/result.json` also passes all 40 checks with the
  current shared JIT body compiled on the original x64 system.
- `build/i386-jit-linked-scope-control-v6/result.json`: linked scopes, detached/
  cyclic rejection, retired operands and saved parent graph, heap and IF checks.
- `build/i386-jit-modrm-original-v1/result.json`,
  `build/i386-jit-current-decoder-x64-v1/result.json` and
  `build/i386-jit-modrm-native-v1/result.json`: twelve decoder cases with exact
  text, lengths and destinations; original catalog reproduction. The middle run
  compiles the current shared decoder under prefixed names on the original x64
  system; its source hash and generated fixture are preserved under build/.
- `build/i386-jit-fixup-kvm8-v6/result.json`: 8 MiB KVM 486,-fpu startup preflight.
- `build/i386-jit-fixup-carry-v1/result.json` and
  `build/i386-jit-fixup-class-meta-v1/result.json`: existing integration contracts.

`build/i386-jit-fixup-public-source-v1/result.json` passes all 25 stages and
follow-up lexer, graph, expression, type, runtime, lifetime, class, function,
statement, ExeCmdLine and stream contracts, with unchanged inputs.

Both `build/i386-jit-fixup-welcome8-v1/screen-oracle.json` and
`build/i386-jit-fixup-diagnostic16-v1/screen-oracle.json` pass the full
307,200-pixel welcome raster. The 16 MiB log completes program phases 0 and 1,
code-heap ownership transitions (0,1)/(1,0), and both file-break cleanup cases.
These resource checks use TCG; the separate KVM preflight also passes.

The final original reference refresh reproduces its previous fixture, helper
source, assertion record and normalized trace byte for byte; its equivalence
audit is retained under `build/i386-jit-fixup-original-v7`.

Failed candidates, first-use trace probes and allocation caller maps remain
under build/. Candidates cross-v6 through cross-v8 passed the JIT component at
64 MiB but failed 8 MiB startup; their results do not qualify resource behavior.
The original shared-core preparation was committed as 3526e7de, with its passing
bootstrap retained in `build/rebuild-jit-decoder-v5-verified`.

This component does not qualify complete assembler/compiler/AOT delivery,
partial-progress failure unwind, all decoder opcodes, 684 remaining inventory
workflows, native self-hosting or the complete C1–C5 release gates. Inventory
qualification remains two of 686 workflows.

Console 254 extends this same first-use service with the complete AOT fixup
routine and preserves all prior exports. The context publishes both entry
pointers, and the existing JIT contract passes on that image. Current AOT and
resource regression evidence is in docs/i386-aot-fixup.md.
