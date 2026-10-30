# Cluster traversal reference work in progress

The fixture `tests/guest/i386-clus-next/Contract.HC` and runner
`tools/test-i386-clus-next.py` are prepared to compare the original public
`ClusNumNext` behavior against a native image. They use copies of a drive and
block-device record and a private RAM-backed four-sector device. The intended
checks cover RedSea traversal, FAT32 chains and end-of-chain, FAT cache block
transitions, mirrored dirty FAT writes, retained outer locks, and invalid drive
and filesystem errors. The expected aggregate mask is 127.

The pinned-original reference passes mask 127 with all five execution inputs
unchanged (`build/i386-clus-next-reference`). This establishes the fixture's
covered original behaviors; it does not establish native cluster traversal or
compatibility qualification. The native control rejects the fixture at
`ClusNumNext` during inclusion, before any contract case runs; all inputs are
unchanged (`build/i386-clus-next-native-red`). The preceding Clus2Blk implementation and its current
validation are described in `docs/i386-clus-to-block.md`.

The reference runner can be repeated with:

```sh
python3 tools/test-i386-clus-next.py --out ORIGINAL
python3 tools/test-i386-clus-next.py IMAGE --out NATIVE
```

The result artifacts are local and are not part of the commit.

The full original `ClusNumNext`, `DrvFATBlkClean`, and `DrvFATBlkSet`
bodies are now shared byte-for-byte through `Kernel/BlkDev/ClusNextCore.HC`
and `Kernel/BlkDev/DriveFATCacheCore.HC`. Both original rebuild generations
pass (`build/rebuild-test`). This source preparation does not bind the native
functions or implement their block I/O dependencies.
