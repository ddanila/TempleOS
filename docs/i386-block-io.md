# Original block I/O reference

`BlkRead` and `BlkWrite` are dependencies of the complete original
block-device initializer and drive path. The reference fixture uses the public
original functions with a copied drive/device record and private RAM backing,
so no physical disk sectors are modified. It passes mask 31 in
`build/i386-block-io-reference-public` with unchanged inputs: zero-count calls,
two-sector write/read and untouched boundary bytes, out-of-bounds exception,
read-only exception, and outer drive/device lock retention. Allocations are
freed after the checks. The fixture does not qualify ATA, ATAPI, ISO files,
cache, removable media, cancellation, or allocation failure.

Two fixture failures are preserved. `build/i386-block-io-reference` declared
externs over the original public declarations and timed out with an undefined
external shown on the captured screen. `build/i386-block-io-reference-source`
attempted to include the original source without its internal declarations and
failed compilation; the screen and executed fixtures are preserved. Removing
both changes uses the original public bindings and passes. The native control
`build/i386-block-io-native-red` rejects the include at the missing `BlkRead`
binding, with unchanged inputs; no native block I/O case ran. Complete native
block I/O and C1–C5 remain open.

```sh
python3 tools/test-i386-block-io.py --out ORIGINAL
python3 tools/test-i386-block-io.py IMAGE --out NATIVE
```

## File-backed device record (2026-10-30)

The complete original `CFile` record and file flags are shared byte-for-byte
through `Kernel/BlkDev/CFileTypes.HH`, included by KernelA and native PublicFiles.
Both original rebuild generations and the cross-build/386 audit pass with 1539
source and 24 build inputs unchanged in `build/i386-cfile-types-cross`. A native
64 MiB field-access check covers all record fields, nested directory-entry data
and file flags, passing four commands with unchanged inputs in
`build/i386-cfile-types-native`; the executed runner is preserved there. Its
61.722402-second concurrent startup is not an isolated timing qualification.
FOpen, FBlkRead/FBlkWrite, block I/O and media initialization remain open.

The complete original `BlkRead` and `BlkWrite` bodies are now shared through
`Kernel/BlkDev/BlockReadWriteCore.HC`. The extraction is byte-identical to
the prior original bodies, and both original rebuild generations pass
(`build/rebuild-test`). This prepares the source for a native provider; it
does not bind or implement the native dependencies or qualify block I/O.

A separate pinned-original cache contract passes mask 15 with unchanged inputs
(`build/i386-block-cache-reference`). On a private RAM-backed drive it checks
cached reads after underlying storage changes, write coherence, and cache
invalidation. It does not cover cache eviction, concurrency, ATA, or ISO.
The native control rejects the fixture at the missing `BlkRead` binding before
any cache case runs, with unchanged inputs (`build/i386-block-cache-native-red`).
No native cache qualification is claimed.
