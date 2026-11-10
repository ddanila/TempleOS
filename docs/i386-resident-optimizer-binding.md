# Checked resident optimizer policy binding

CompilerRuntime now publishes `_I386_OPT_CORE_POLICY` as entry 6 of its retained
export enumeration. Entries 0–5 keep their names, kinds, target functions and order;
the enumeration now terminates at entry 7. Compiler service structure layout,
version and function signatures remain unchanged. This is an append-only named
binding extension, with the kernel's exact publication count updated from six
to seven. The rebuilt kernel and compiler are packaged together; historical
kernels expecting six exports are not the matching kernel for this candidate.

KernelResidentPublish validates the name, target range, kind and uniqueness of
all staged exports before publishing them. The new binding names the complete
OptPass012CorePolicy implementation added in the previous checkpoint. The host
module audit now requires that function export, and requires the new native
routing diagnostic in the program-probe image.

No public optimizer facade is switched in this change. The public source path
still includes its complete implementation. A later bridge must preserve public
branch allocation, diagnostics, helper visibility, canonical types, opcode
metadata semantics and lifetime before it can share the resident core. The
original-User 8 MiB failure remains unresolved.

## Native execution check

`Kernel/I386/OptimizerPolicyProbe.HC` runs in both native program diagnostic
rounds. It resolves the published name, compares it with export enumeration
entry 6, checks the kernel export kind and compiler-image bounds, then calls
through that exact binding. The export record uses CI386KernelSymbol, whose
kind field extends the public CHashExport record; the public base type alone
has no kind member.

The test supplies stack-owned controls derived from the public control shape,
a stack-owned parser stack and valid immediate/branch graphs. Its callbacks
count calls in the derived control, so there is no global policy or counter
state. Over passes 0/1/2 it requires exactly three calls to the selected callback
and zero to the other, for both zero and nonzero branches. With the existing
CCF_TARGET_I386 flag it requires neither callback. Unexpected reports stop the
probe, and heap bytes/allocation counts must remain unchanged. This checks
native dispatch and binding ABI without feeding public-shaped controls to
private allocation validators. Instrumented callbacks do not qualify the
original branch rewrite algorithm or complete public-core integration.

The program diagnostic also checks entry 6's name/kind and rejects entry 7,
while preserving the existing export checks. Success emits one
`OPT RESIDENT POLICY` marker for each phase, followed by the normal complete
program-probe result.

## Evidence

`build/resident-opt-binding-v3` cross-builds Kernel, CompilerRuntime and
CompilerProgramRuntimeProbe with the retained bootstrap, relinks the kernel
with the unchanged five context modules, and regenerates the checksummed boot
stage. Full 386 module and boot instruction audits pass. Exact image checks
replace those three modules and matching changed sources, add the diagnostic
source, preserve every unrelated file and publish the audited boot bytes.
The compiler module grows by 200 bytes; the normal kernel module size is
unchanged. The reclaimable program diagnostic grows by 5,817 bytes.

Candidate SHA256:
`3c062f8d3885471532295fdbfbbb42f9149089109c7357e419c898e9ec1de893`.

- Production managed-pointer User at 8 MiB: PASS.
- Public source optimizer against the pinned original at 16 MiB: PASS, exact
  48-word trace, 18 state checks, zero caller heap deltas and fresh arithmetic.
- Complete native compiler/program diagnostics at 16 MiB on `486,-fpu`: PASS
  through both rounds, including exactly one new binding/routing marker per
  phase, existing boundary/completion checks and DocAllocationCheck=13.

`build/resident-opt-binding-audit-v1` rehashes inputs and receipts, verifies
actual RAM/CPU commands, exact module/source/boot packaging, and preservation
of the old export implementation. The final successful cross build is v3;
v1 omitted the changed split program-probe module, and v2 failed compilation
when it used the public base record for a kernel-only field. These attempts
are excluded from runtime evidence and retained separately.

This establishes publication and native invocation. It does not establish a
public facade using the binding, malformed-policy handling, full desktop/apps,
two current native generations or startup/resource release qualification.
C1–C5 remain open.
