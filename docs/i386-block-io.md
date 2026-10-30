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
