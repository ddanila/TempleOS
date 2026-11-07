# Variable initialization controls

Normal startup now exposes the original U8 sys_var_init_flag and sys_var_init_val
as shared kernel data. Their defaults are zero, matching the actual original
reference. Kernel export slots 93/94 are data entries; existing slots keep their
identities. Compiler runtime version 85 imports both controls, with the interface
layout unchanged. Console version remains 245.

Enabled initialization fills global and static allocations with the selected
byte before explicit initializers run. Disabled initialization leaves the
allocation alone, matching the shared original callback; the native callback no
longer forces zero independently of the flag. Uninitialized contents with the
flag disabled are not used as an oracle.

The shared i386 backend snapshots the controls when compilation begins. Ordinary
function prologues fill only the allocated local-frame region after saving
callee registers, leaving arguments and saved frame state outside that region.
Interrupt functions skip this path, as in the original backend. Both measuring
and emitting passes use the snapshot; compiled functions retain their pattern
after the public controls change. Host, private-native and source-loaded public
backend adapters use the same policy fields.

Run tools/test-i386-variable-init.py --out OUT for the original, or supply a native
image before --out. Original-v2 and normal native-v1 pass mask 255 and their full
40-byte records match exactly. Eight checks cover control writes, an uninitialized
global array, explicit global initializers, a static local, a noreg I64 local,
a 17-byte stack array, two compile-time patterns and control restoration with
continued execution. The old native image rejects missing sys_var_init_flag at
line 18 (baseline-v2). The first reference fixture used noreg before the type and
entered the original debugger; the corrected fixture uses I64 noreg/U8 noreg,
as demonstrated by the bundled assembly example. That failed trial is retained.

Both x86-64 bootstrap generations rebuild and boot with stable source pins;
this is not bit reproducibility or C5 i386-generation qualification. The full
native build passes source pins and 386 instruction auditing. Both 8/16 MiB
profiles match all 307200 welcome pixels, and both diagnostic program, ownership
and file-cleanup phases pass. Independent policy and integration audits verify
current inputs, exact original records, fixture-only volume changes and boot
bytes.

The complete shared declaration/initializer services now publish as a twentieth
source-loaded stage, passing all existing token/graph/basic/type/runtime/lifetime
regressions. The earlier probe failed at the missing control. Class/function-header
and AOT code-store services still need integration; publication is not complete
compiler delivery. Register-local policy, interrupt behavior, allocation/error
paths, all storage/type combinations and full C1–C5 qualification remain open.

Evidence: build/i386-variable-init-original-v2, build/i386-variable-init-baseline-v2,
build/i386-variable-init-native-v1, build/i386-variable-init-cross-v1,
build/i386-variable-init-memory-audit.json and build/i386-public-declarations-source-v2.
