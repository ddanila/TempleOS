# Deterministic native image packaging

`tools/package-i386-native-image.py` places an already built native image's
live RedSea tree in sorted order. It does not compile sources or replace native
modules. It preserves every live file's bytes, attributes and date, every live
directory, and the entire reserved native boot area. It removes tombstones,
unused directory capacity and unreachable data, and regenerates the bitmap.
Dates are preserved rather than normalized: differing file dates should remain
visible as a reproducibility difference.

The input must pass the existing independent RedSea ownership audit and have
no pending filesystem journal. The output must be a fresh path. Packaging
verifies the resulting bitmap and ownership, compares file attributes, dates
and contents, and reads every file through the existing independent reader.
The input image must remain unchanged. A JSON report is written next to the
output image. Packaging does not establish that an image is release-qualified.

To compare two separately installed native generations:

```sh
python3 tools/package-i386-native-image.py path/to/gen1/target.img --out build/release-gen1.img
python3 tools/package-i386-native-image.py path/to/gen2/target.img --out build/release-gen2.img
cmp build/release-gen1.img build/release-gen2.img
```

Run the native executable audit and runtime workflows against the packaged
image itself. Its hash differs from its source, so an earlier installed-image
qualification cannot be transferred to it by editing a provenance report.

On 2026-10-05, the TEST-fixed candidate's two completed native generations
produced identical packaged images in `build/native-release-packaging`:
SHA256 `a25fc4a39eda36441e8000669934def9c850e6a48f9951c43197806de016d7b9`.
All 873 live files match in contents, attributes and dates before packaging.
The boot area remains identical. Both packaged filesystems have 16 directories,
873 files and 19275 uniquely owned sectors; the one-sector reduction reflects
compacted directory capacity. Repackaging is byte-identical; existing output
and pending-journal inputs are rejected.

The packaged generation2 passes the independent native executable audit in
`build/native-release-packaging/native-audit/result.json`, including boot
metadata, payload padding, linked executable ranges and filesystem ownership.
The first audit invocation omitted `--guest-compiler-template` and failed its
cross-built compiler marker check; that failed output is preserved separately
in `build/native-release-packaging/audit`. The successful invocation uses the
same native compiler audit mode as the generation qualification runner.

This evidence is tied to the TEST-fixed source epoch, preceding memory-baseline
and public Caller changes. Those newer candidates require their own full native
and packaged-image qualification. Whole workstation regression and final release
promotion remain required.

The packaged image also passes normal interactive boot and VGA-checked `6*7`
on 8 MiB with `486,-fpu` in `boot-result.json`; its hash remains unchanged.
Focused compiler, file-navigation, documents and document-editing gates are
running on a fresh writable copy in `build/native-release-packaging/workflows`.
These are additional runtime checks, not yet a full workstation qualification.


To run all four installed workstation gates on the packaged descendant, retain
its original native construction result and supply both origin inputs:

```sh
python3 tools/test-i386-installed-workflows.py \
  --disk build/release-gen2.img \
  --native-disk path/to/gen2/target.img \
  --packaging-result build/release-gen2.img.json \
  --native-result path/to/gen2/result.json \
  --installed-audit path/to/packaged-audit/result.json \
  --out build/packaged-workstation
```

The native result must match the original disk. The installed audit must match
the packaged disk and the native flat kernel hash. The runner independently
repackages the original disk and compares every byte before launching the four
frozen helpers. It pins the additional inputs throughout the run.
`tools/test-i386-packaged-origin.py` records six provenance acceptance/rejection
cases using real native artifacts, including altered boot bytes hidden behind
forged matching report hashes. This gate passes in
`build/native-release-packaging/origin-mutations.json`.

The memory-baseline epoch also completes both native generations and yields
identical whole packaged disks in `build/memory-baseline-release-packaging`:
SHA256 `177ffbd736f9ae5010377ccb8dcd9b2b22220ab151e1baeee4c8a5087f3a90d9`.
These images have their own delivered source/runtime modules and still require
packaged runtime qualification. Neither packaged epoch proves qualification of
the newer public Caller candidate.
