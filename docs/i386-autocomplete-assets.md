# Autocomplete dictionary assets

The pinned original word list is 1,253,930 bytes and the definitions file is
26,381,073 bytes. The normal 16 MiB native image cannot carry both. A 64 MiB
native cross-build and 386 audit pass at
`build/i386-autocomplete-assets-cross-64m`; this is disk capacity, not a guest
RAM or full desktop qualification.

The pinned original system compressed the word list with `CompressBuf` and
expanded it back byte-for-byte (`build/i386-autocomplete-archive-original`).
The resulting 476,217-byte archive and the unchanged definitions file were
added without replacing existing files in
`build/i386-autocomplete-assets-package`. The archive has the RedSea
compressed-file attribute, while the definitions file remains uncompressed
for block access. Both source assets match the compatibility inventory, and
the package preserves and independently verifies existing bytes, metadata and
boot area. The packager accepts explicit compressed attributes only for a
validly formed archive header and rejects invalid attributes without producing
an output image. The additive package regression passes with compressed and
ordinary files, idempotence, and ten rejection cases.

A 64 MiB native guest passed dictionary lookup, complete word-list expansion
and byte-identical readback with unchanged inputs
(`build/i386-autocomplete-assets-native`). The 8 MiB initial welcome-screen regression for the shared input helper passes
with unchanged inputs (`build/i386-autocomplete-helper-welcome-8m`); its
concurrent startup is not a timing qualification. `FOpen` and block reads, dictionary initialization,
suggestions and C1–C5 remain open.
