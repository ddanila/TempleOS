# Disk cleanup, 2026-11-10

Work performed directly on `main`. Continue personal-project work on `main`
(or `master` if renamed), as required by `AGENTS.md`.

At inspection, the filesystem had 236 GB available (73% used). This checkout
occupied about 177 GB, almost entirely `build/`. The largest artifact classes
were compressed archives (90 GiB), ISOs (20 GiB), and disk images (18 GiB).
Outside this checkout, `../money-for-nothing-486` occupied 224 GB; its files
were left untouched.

Compressed 2,201 raw PPM screenshots older than 24 hours into adjacent
`.ppm.zst` files, recovering **2,011,598,848 bytes (1.873 GiB)**. Each archive
was fully decompressed and its SHA-256 matched before removing the raw file.
Open files were excluded. Unique screenshot evidence remains recoverable.
Running test jobs and recent screenshots were left alone.

Older archives had no further exact duplicates. Zero-block deallocation of
209 older images/ISOs preserved their SHA-256 and recovered no space because
they were already sparse. No sources, test receipts, historical worktrees,
or unique build evidence were deleted.

Local accounting and recovery files are in
`build/cleanup-2026-11-10-artifacts/`. From the repository root, restore an
original screenshot path before rerunning a tool that expects raw PPM:

```sh
python3 build/cleanup-2026-11-10-artifacts/restore-screenshot.py build/path/screen.ppm
```

Use `--all` to restore all screenshots. Keep the compressed files and
`screenshots-manifest.jsonl`. The restore helper was tested on one screenshot,
whose restored SHA-256 matched the manifest; its redundant raw copy was then
removed again. Every archive was independently verified during compression.
