# Cluster traversal reference work in progress

The fixture `tests/guest/i386-clus-next/Contract.HC` and runner
`tools/test-i386-clus-next.py` are prepared to compare the original public
`ClusNumNext` behavior against a native image. They use copies of a drive and
block-device record and a private RAM-backed four-sector device. The intended
checks cover RedSea traversal, FAT32 chains and end-of-chain, FAT cache block
transitions, mirrored dirty FAT writes, retained outer locks, and invalid drive
and filesystem errors. The expected aggregate mask is 127.

The pinned-original run is queued behind the isolated Clus2Blk resource gate;
neither the fixture nor its expected result has been verified yet. No native
cluster traversal implementation or compatibility qualification is implied by
this test preparation. The preceding Clus2Blk implementation and its current
validation are described in `docs/i386-clus-to-block.md`.

The queued coordinator records its state in
`build/i386-clus-next-reference-queue.json` and will put the reference results
in `build/i386-clus-next-reference`. These build artifacts are local and are
not part of the commit.
