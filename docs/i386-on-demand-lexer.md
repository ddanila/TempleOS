# On-demand full lexer prototype

The full shared lexer now loads as a native module when first needed. The
corrected V9 image passes all 24 public lexer cases at both 8 and 64 MiB. It also
passes complete live prompt, exception/compiler-error/physical-break recovery
and physical User reclamation at 64 MiB. The unchanged 8 MiB User regression
still fails later while loading compiler support. This is not production or
C2/C5 qualification.

The reviewable implementation is
`docs/patches/i386-on-demand-lexer-prototype.patch`. It includes the previous
original-loop/ownership changes and applies to current main. Production source
is unchanged by this patch until integration is qualified.

## Loading and ownership

`LexRuntime.HC` compiles the full shared lexer bodies, retaining string, numeric,
character, identifier, punctuator, define, conditional and include paths. Its
54,208-byte T32M has 30 explicit runtime imports. Mutable bitmaps, run-level flags,
compiler globals and block globals bind to the existing system objects. The
LexAttachDoc import matches all six parameters of the public ABI. No token
cases or source bodies were removed.

Console asks Adam to serialize first-load publication. The private provider
interface checks its version, size and callback addresses against the validated
loaded image. Token arrays belong to Adam; the loaded image belongs to the
kernel heap and remains live with the system. Failed loads release temporary
storage in its actual allocator domain before propagating the exception.
LexIncludeStr is appended to the console export vector without changing old
indices, and its public declaration supports the original shared parser.

A public FileRead buffer cannot fit the initial 8 MiB allocation pattern. Reading
raw bytes into the kernel heap succeeds, but allocating a separate executable
copy still fails: a 51,272-byte request exceeds the largest 17,096-byte free
block in the retained V8 trace. The final loader reuses the existing validated
single-module compactor instead. A private kernel shim normalizes the raw
reader's extra NUL allocation byte, then calls I386ModuleCompactOwned. Existing
validation, import resolution, relocation and heap shrinking remain in force;
the general loader's overlap rejection is unchanged. Ownership transfers from
the raw buffer to the compact executable allocation exactly once.

The private Console binding gains only I386CompactReadModule. The prototype
audit keeps the existing exact import set and adds that one name explicitly.
All 17 modules receive the complete386 audit, including the on-demand provider;
the rebuilt flat kernel and BIOS/protected-mode boot stage are also audited.
Packaging replaces the matching modules/sources, adds the provider, verifies
unrelated files unchanged and verifies the rebuilt boot area separately.

## Current evidence

Artifacts are under `build/on-demand-lexer-v9`:

- Candidate disk SHA256:
  21745af3cd9be827460b3571b2d83ec2ac2fe85fc378571111778f3f11b308b2.
- LexRuntime SHA256:
  938db2cac33c2846e4fb6966d2ea31f8770369a9ca9676481e6ecfcb403b53e3.
- ConsoleRuntime SHA256:
  f3c6b864f441ca29e64b7783a6d7dfd32483ab57b264d3a43800840f106cb2e0.
- Flat kernel SHA256:
  e3ad5a9f42971d252b810cfb074b2c699b9b5e3907aecc1a37589a1f51ded3f2.
- Patch SHA256:
  7975451d2444d7d5072800d81419bbc3abfb0d752d9ad996f5a1862795bade63.
- `public-lexer8-profiled-v1/result.json`: PASS, SHA256
  60722130da67167997fe493eec85f4b4d818458530ad07158100324deabdaf6a.
- `public-lexer64-profiled-v1/result.json`: PASS, SHA256
  fd13521c35ffa7c6eba3bc7de7264e461cd349c783f170920815dd5b6927e804.
- `live-recovery/result.json`: PASS, SHA256
  6e489e321fc60694b236373da6fabe56956ac261ad48f5bbd2c11b8a46c9e529.
- `user8/result.json`: FAIL, SHA256
  c1e8b20cbac55a372cc818eebcf853eef14fd3e60c351265a1bedde0dd328779.

The independent `build/on-demand-lexer-audit-v1/result.json` passes, SHA256
6966f9bd1e3792621c2660857fb22a25dc5fe1eb40f5ffd81a7780624c4c327b.
It rehashes source/overlay/helper inputs, checks the bootstrap binaries and all
24 exact result words, and verifies actual QEMU RAM/CPU arguments separately
for the 8/64 MiB runs. The lexer harness now records RAM in its receipt and
requires exactly one selected initialization marker and zero markers for other
storage modes. Default source loading also passes independently:
`build/lexer-provider-source-regression-v2/result.json`, SHA256
f246f6a62a2a024a39f8bb7545c40ac1cd39793a024b244cd968f634e4c8c40c.

```sh
python3 tools/test-i386-public-lexer.py IMAGE --lexer-storage provider --ram-mib 8 --out FRESH_LEXER
python3 tools/test-i386-live-user-prompt.py --recovery --disk IMAGE --out FRESH_RECOVERY
python3 tools/test-i386-user-startup.py IMAGE --managed-pointer --accel kvm --ram-mib 8 --out FRESH_USER
```

## Remaining memory and integration work

V9 reaches `PUBLIC LEX provider` at 8 MiB, then fails a 12,717-byte allocation
with a largest free block of 10,552 bytes. The decoded callers are
NativeResidentCopyHeap and NativePublicFileReadHeap. The requested size matches
PublicDocument.HH plus its terminator; private optimizer/compiler declarations
include that header. This points to compiler-support file/metadata loading as
the next memory investigation, rather than failed provider relocation. It does
not prove that all later allocations will fit once that request is resolved.

Earlier variants remain retained: V1/V2 hit declaration dependencies, V3 a
forward-header conflict, V4 a missing software-float import, V5 builds the
provider, V6 integrates but has an incomplete LexAttachDoc declaration, V7
corrects that ABI, and V8 exposes the separate-copy allocation failure. V6 is
excluded as qualification even though its include-free prompt path passes.
V9 supplies the corrected public lexer and recovery evidence above.

Production integration still requires the 8 MiB User gate, malformed-load and
broader lifetime coverage, native build/install manifest support for the new
provider and updated strict build contracts. Two current native generations,
full desktop/application/API coverage and startup/resource qualification remain
open. Existing 8 MiB interactive / 16 MiB rebuilding / 60-second startup gates
are unchanged. C1-C5 and inventory 2/686 remain open.
