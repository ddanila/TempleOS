# Kernel build date and HomeSys compilation

The original HomeSys prints `sys_compile_time` in its startup banner. The
native image had no public binding, so loading the actual file with
CCF_JUST_LOAD failed at that identifier. The retained attempt is
`build/home-startup-preflight-v1`; its separate Once-path failure does not
explain or excuse the HomeSys compilation error.

The kernel now captures Now during compilation using the same #exe/StreamPrint
mechanism as original Kernel/KStart16.HC. Its eight-byte scalar lives in the
loaded kernel image. Console ABI274 borrows that address through its versioned
configuration and publishes the original CDate `sys_compile_time` name as data.
The public kernel header includes DateTypes before declaring it. The value is
neither the boot clock nor an invented constant. Existing exports retain their
indices; the appended entry is explicitly marked as data in the export bitmap.

This exposed a cross-compiler defect: the x64 host statement adapter retained
CCF_TARGET_I386 during #exe execution. The host must execute compile-time code
with its own calling convention and pointer width, then resume the target.
PrsHostExecuteLine now clears only TARGET_I386/TARGET_HOST_CONST for that call
and restores those bits on normal return and exception. The native statement
adapter continues to use its actual 32-bit execution environment.

`tools/test-i386-host-stream.py` tests an actual 386 AOT source unit. The
pre-fix compiler fails mask2; the fixed compiler passes31 at
`host-stream-before-v5` / `host-stream-fixed-v5`. The generated module records
host pointer size8, an actual host StrLen result6, and a four-byte target pointer
allocation. A public Lex invocation raises an escaping exception inside #exe;
both target bits and the previous compilation-control chain restore, and a
fresh module matches every byte of the first. Fixture/source/control records
and emitted modules are retained. Earlier fixture prototypes used an unavailable
private adapter name, omitted the target type header, or lacked the runner's
required DONE prefix; none is the accepted regression baseline.

`tools/test-i386-system-build-date.py` verifies the public value and address
against Kernel.t32m, the linked Kernel32.BIN and the actual source disk. It
requires the value to remain fixed while Now advances, independently decodes
its calendar fields, and checks original date/time formatting. It frees its
formatted buffer, loads the actual HomeSys in Adam after original MakeAC, then
requires fresh42 and an unchanged complete volume. The ABI273 image fails at
sys_compile_time (`system-build-date-before-v2`); ABI274 passes at
`system-build-date-native-v3`. The accepted timestamp is3179538462258213 at
address0x100008, decoded as2026-11-09 23:40:50 UTC.

The optional `--native-kernel` mode builds the complete kernel module twice on
the native 486,-fpu guest at128MiB. It checks exported names/kinds against the
cross-built module, then compares every byte of the two native outputs except
each fresh eight-byte timestamp, located through its own export record. The
packers use different function/global ordering, so cross/native raw byte
identity is not the reproducibility oracle. The running kernel's public date
must stay fixed; fresh42 and every prior file must survive. Only the two built
modules may be added. Build dates naturally change on recompilation; this explicit
single-field comparison is distinct from a whole-image bit-identity claim.
C5 still requires two complete installed native generations, their full suite
and declared reproducibility/resource profiles.

The disposable integration preflight (`home-startup-preflight-v3`) reaches the
original StartUpTasks body and its configured Once. That runner's shared
COMMAND OK marker can come from a child, so it alone does not prove the whole
Adam job returned. Later `bootstrap-retirement-before-v3` and
`bootstrap-retirement-candidate-v3` log BOOT EXIT START directly after the
actual Adam call returns, providing that stronger completion evidence. The
fixture installs custom Once at the actual lookup path through FileWrite.
These remain explicit preflights: delivered normal boot, complete raster,
autocomplete content and resource qualification are separate. See
[i386-bootstrap-retirement.md](i386-bootstrap-retirement.md).

The candidate is `build/i386-system-build-date-cross-v3/kernel.img`, with1868
source and26 helper pins. Two source-matching classic rebuild generations and
the386 audit pass. Only Kernel and ConsoleRuntime differ from ABI273; the bare
kernel is458744 bytes. Classic rebuilding does not qualify native C5 generations.
The first native boot attempt exposed a missing DateTypes dependency in the
new declaration; that image and its failure receipt remain preserved.

Regression receipts include `build-date-pen-recovery-v1` (all12 throw/Kill/Exit
cases, exact logical recovery/backing reconciliation and all391680 pen bytes)
and `build-date-user-8m-v1` (stock User255 at8MiB with the full managed pointer).
Default-refresh MsgLoop and isolated startup checks are recorded separately.
Inventory remains2/686; full C1-C5 remain open.

```sh
python3 tools/test-i386-host-stream.py --out HOST
python3 tools/test-i386-system-build-date.py IMAGE --out DATE
python3 tools/test-i386-system-build-date.py IMAGE --native-kernel --out NATIVE_KERNEL
```

The actual native kernel attempt is retained at
`system-build-date-native-kernel-v2`. It parses the complete source without
errors, including the new timestamp directive, but fails module packing at
stage5: `MODULE PACK REJECT global-pointers i386_lex_doc_format`. It is not a
native-kernel pass. The callback global is zero in the cross-built module; the
native frontend currently applies its JIT initialization policy to source-unit
storage, which needs a focused AOT-zero-initialization comparison before a fix
is accepted. The failed build and complete module-packing trace remain intact.
The earlier native-kernel-v1 probe had an overlong character literal in its test
guard and never attempted the build; it is not the accepted failure baseline.

`build/system-build-date-audit-v1/verify.py` rechecks1868 source/26 helper pins,
classic rebuild identity, before/after raw compiler records, loaded timestamp
bytes/address, HomeSys loading, all12 cancellation trials, stock8MiB User and
both complete default-refresh MsgLoop documents/streams/framebuffers. This audit
covers the listed checkpoints; the native packer failure remains explicitly open.

Both `build-date-msg-loop-{shift-}native-v1` runs pass complete original saved
documents/streams, all614400 pixels, restoration7, fresh42 and unchanged volumes
under the default refresh policy with observed phase barriers. Isolated normal
8MiB KVM486,-fpu startup is54.262s at `build-date-startup-8m-v1`, with no other
QEMU at invocation, live WinMgr and exact managed welcome/42 pixels. This is
only the existing60-second baseline subgate. The audit also verifies that the
failed native build preserved the complete input file tree and published no module.
