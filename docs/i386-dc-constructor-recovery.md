# Device-context construction survives native task cancellation

A child can initialize the shared pen cache on Adam's heap and be killed while
its graphics body allocator yields. The pen guard owns completed table entries;
it cannot reclaim the current context before DCNew returns and publishes it.
`pen-init-recovery-before-v3` exposes one leaked392-byte allocation span in each
of four Kill cases. The object requests376 bytes; allocator bookkeeping and
rounding account for the tracked392-byte span. Ordinary exception cases recover
Adam's logical heap exactly.

The shared DCNew constructor now opens an optional native construction scope
before allocating its header. The scope points to its local context variable
and owns the unpublished header plus assigned pixel/matrix buffers until the
constructor commits. Native task retirement releases those partial resources
before the enclosing pen guard clears completed entries. Ordinary C exception
cleanup also clears the local pointer and closes the scope. Successful return
transfers the context to its caller.

RenderScope.HH shares the identical existing base record with the early context
implementation; render-scope functions and their cleanup/retirement policy stay
in RenderScope.HC. The constructor adds a stack record, with no extra heap
allocation. ConsoleRuntime opts into the native hooks. Classic and standalone
users of GrDCCore retain empty hooks and ordinary exception cleanup. Header
allocation now occurs inside that cleanup block, with a NULL-safe failure path.
The compile-only mouse probe reads the extracted record from its new header.

`tools/test-i386-pen-init-recovery.py` runs on the normal delivered image. It
locates private data slots through the actual ConsoleRuntime module exports
and live module base. It temporarily replaces the existing body allocator;
pen construction, public GrFillCircle, task creation, Kill, constructors and
cleanup remain the actual implementations. The wrapper throws before allocation
or yields until Kill at body-call1,33,128,256, after two warm failure cycles.
All192 raw metric quads are retained. Every case requires all pen pointers and
bounds cleared, ready/builder state reset, the previous scope chain restored,
exact Adam/caller logical-heap recovery and successful task retirement.

Physical backing is accounted separately. Pool caches can grow or trim during
otherwise leak-free calls. The test walks owned backing regions, validates each
actual heap block tag/span/request, reconciles retained totals and partitions
main/fallback regions. Changes in the main heap's used bytes and allocation
count must equal changes in validated backing spans and region counts. The
first prototype incorrectly demanded raw zero growth; its complete measurements
remain at `pen-init-recovery-before-v2`. The refined baseline proves all physical
changes are accounted while all four Kill cases still leak392 logical bytes.

`pen-init-recovery-fixed-v2` passes all eight cases with zero Adam and caller
logical deltas. The actual allocator slot is independently read before/after
and must equal the original MemoryCAllocExact entry address. A public retry then
matches all391680 pen-table bytes against the independent geometric model;
fresh42 passes and the complete native file tree remains unchanged. Failure
and success receipts and the executed runner snapshots remain distinct.

The final full-profile image is
`build/i386-dc-constructor-scope-cross-v1/kernel.img`, Console ABI273. It pins
1868 sources and26 helpers, passes two source-matching classic rebuilds and the
386 instruction audit. Only Kernel and ConsoleRuntime change from ABI272;
bare kernel remains458680 bytes. These classic generations do not qualify C5
native self-hosting.

Regression evidence:

- `dc-constructor-context-v1`: the unchanged20 graphics-context groups and two
  allocation-recovery checks pass through public APIs, then fresh42 and an
  unchanged complete volume.
- Both `msg-loop-dc-scope-{shift-}native-v1` controlled cases match complete
  original documents/streams and all614400 pixels, restore7, then pass fresh42
  and unchanged volumes. Default scheduling remains separately unqualified.
- `dc-constructor-control-retirement-v1`: nested return/Exit/Kill with recovering
  end callback retains all three255 masks and caller recovery.
- `dc-constructor-user-legacy-v1`: actual User/editor transition matches614400
  pixels and exact saved bytes, restores document roles, preserves prior files
  and passes fresh42.
- `dc-constructor-user-8m-v1`: stock User255 passes at8MiB, with the original
  pointer included in the welcome/command oracle.
- `dc-constructor-startup-8m-v1`: isolated normal8MiB KVM486,-fpu startup54.265s,
  live WinMgr and exact welcome/42 pixels, with no other QEMU at invocation.
  This is the current60-second baseline subgate only.

`build/dc-constructor-audit-v1/verify.py` rechecks source/helper/bootstrap pins,
raw recovery records, allocator restoration, delivered fixtures/volumes, complete
pen retry bytes, and entire original MsgLoop documents/framebuffers.
Other allocation points, explicit Exit within this constructor, reentrancy,
DCAlias construction and all-resource/default-desktop/native-generation
qualification remain open. Inventory stays2/686; full C1-C5 remain open.
