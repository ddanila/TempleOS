# Original MsSet semantics and public mouse messages

The native public mouse header now binds `MsSet` and `GridInit`. The original
`MsSet` body is shared through `Kernel/MouseSetCore.HC`, with only its function
name parameterized. A byte comparison against the pinned original confirms the
body is unchanged. Native `MsSet` serializes the update with IRQ input and
preserves the caller's IF state.

The call updates public coordinates/buttons immediately, using the original
omitted/invalid-argument rules and scale/offset/grid conversions. Its hardware
position base is then quantized through the hardware scale and grid speeds.
Scheduled processing consumes that position later, preserving the original
immediate-versus-settled difference for non-unit grid speeds.

Synthetic calls replace pending synthetic state before WinMgr runs; a transient
press/reset does not fabricate a callback or mouse message. Already queued
physical packet positions and cumulative z are rebased, so their relative
movement remains after the newly requested base. The IRQ observer's position
also moves to that base. The extra native raw `MouseGet` API continues to expose
the independent kernel hardware observer; synthetic calls do not increment its
packet count or alter its raw coordinates/buttons.

Keyboard-state publication and delivered key scans use the logical mouse button
state. This preserves synthetic buttons across keyboard input until a real mouse
packet replaces them. WinMgr control dispatch stops after its first handled
control, matching the original left-control priority for the tested simultaneous
left/right transitions. Release bookkeeping clears the relevant gesture even
when the message recognizer's last code belongs to the other button.

Visible, valid raw focused tasks now receive public mouse messages independently
of managed rendering. Direct document actions still use managed document
admission; retained legacy view scopes keep their existing input path. The
existing keyboard-only reader discards unmatched messages through `ScanMsg`,
while an application can explicitly collect mouse messages.

The Console semantic interface is 266, with 693 named bindings. Kernel and
ConsoleRuntime are the only changed compared module outputs against the wheel
image. Kernel remains 457416 bytes. The source-matching classic bootstrap passes
both generations; the full-profile native build and 386 instruction audit pass.
The image pins 1860 delivered sources and 26 build helpers. The host module
validator accepts 266 and rejects a mutation to 265; live mixed-module boot is
not tested here. Classic bootstrap generations are not C5 native generations.

## Direct evidence

See [the original oracle record](i386-mouse-set-oracles.md) for fixture details
and retained failures. The final source-matching artifact is
`build/i386-mouse-set-cross-v4/kernel.img`. All sixteen native modules and its bare
kernel are byte-identical to v3; all 1887 volume file contents also match except
one removed trailing separator blank outside the copied function. The comparison
is recorded in `mouse-set-audit-v1/final-image-equivalence.json`; metadata dates
are not claimed identical. Runtime captures below use v3 and apply to these
identical modules. The rebuilt classic comparison used the same function body
before that separator cleanup.

- `mouse-set-native-v4`: 32 immediate/settled rows, all 544 original/model values
  plus 32 delivered `ScanKey` mouse-button bits,
  mask 7; omitted/invalid arguments, scaling, snapping, grid speed quantization,
  synthetic button/key state and physical motion/wheel/button follow-up.
- `mouse-set-controls-native-v3`: nine phases, six exact original callbacks,
  coordinates, yielding task/owner/IRQ identity and mask 7. The v1 candidate's
  strict eight-versus-six callback failure is preserved.
- `mouse-set-messages-native-v3` and `mouse-set-messages-raw-native-v3`: eight
  phases and six exact original messages each, requested/actual mode and mask 7.
  The v2 raw candidate's strict zero-message failure is preserved.
- `mouse-set-current-classic-v4`: the source-pinned rebuilt classic system also
  matches all 544 state values, 32 delivered key-button bits and mask 7.
- `mouse-set-queue-v2`: mask 63 in the exact source probe for pending queue
  rebasing, overwrite, wrap/guards/metadata, grid speed and clipping, plus real
  raw-API/IF/heap preservation. Its clock/init are stubs; it is not a live pending
  IRQ-interleaving test. The probed source is unchanged in v3.
- `mouse-set-audit-v1/result.json`: independent model/original/native comparison,
  755 single-value corruptions rejected, retained negative captures and fresh 42
  glyph pixels recomputed from the original font. Passing native workflows
  preserve fixture files/metadata and input hashes.

Physical regressions on v3 also pass:

- `mouse-set-controls-managed-v3`, `mouse-set-controls-raw-v3`,
  `mouse-set-wheel-v3`: exact original physical control/wheel workflows.
- `mouse-set-gain-v3`: all 62 physical-input phases/744 original values.
- `mouse-set-click-lifetime-v3`, `mouse-set-wheel-lifetime-v3`: five 255 modes
  each, including throw, recovering/committed Exit and owner retirement.
- `mouse-set-help-v3`, `mouse-set-picker-v3`, `mouse-set-state-8m-v3`: all
  pixels match at 8 MiB KVM 486,-fpu/live WinMgr; state mask 63. Those concurrent
  startup measurements do not establish the isolated 60-second C5 gate.
- `mouse-set-raw-api-v3`: six raw/logical/button snapshots, mask 15.
- `mouse-set-budget-v3`: full Budget save/real cold-reopen/abort masks 1023/63,
  exact reports/live tuples/records and 1887 prior files preserved; unchanged
  cold-reopen files/metadata and fresh 42 in both sessions.

`mouse-set-device-v3` still fails console typing with left held after the initial,
motion and logical pointer checkpoints pass. Its typing frame is pixel-identical
to `mouse-gain-device-v1`. `mouse-set-doced-v3` retains the unflagged editor's
113/95 state results, exact text and 524/609 client-pixel differences against the
original. These are explicit failed gates, not passing whole-group checks.

`mouse-set-startup-8m-v5` boots the final v4 image at 8 MiB KVM 486,-fpu with
live WinMgr and a fresh 42, with all checkpoint pixels matching. Startup takes
53.959 seconds with no overlapping test/build jobs and no other QEMU processes
at invocation. This meets the 60-second threshold for the current normal-boot
baseline; it does not qualify the full original desktop, all application/resource
profiles or complete C5 acceptance. An initial wrapper invocation in v4 was
rejected before boot for combining startup checks with group selection.

Public `ms_hard`, complete velocity/timestamp parity, all queued IRQ/FIFO/loss and initial-state/focus/callback mutation
permutations, arbitrary/invalid scale settings, missing-device behavior, legacy
view transitions, complete desktop/raster/resource behavior, and every bundled
application remain unqualified. The held-click console and unflagged DocEd
failures remain open on the current image. No full-file or C1–C5
qualification follows from these workflows; the inventory remains 2/686.
