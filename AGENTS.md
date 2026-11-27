# Repository workflow

This is a personal project. Work directly in `main` (or `master` if the default
branch is renamed). Do not create feature branches or additional worktrees for
new work. Existing experimental worktrees are historical evidence, not the place
to continue development.

Commit and push completed, verified changes within the active task's scope to
Danila's fork. Verify the remote destination first; do not push or open pull
requests upstream unless explicitly requested. Keep unrelated or unfinished
changes out of those commits.

Preserve unique build/test evidence during disk cleanup. Redundant generated
artifacts may be removed after verifying the retained copy or a lossless recovery
path. Keep cleanup manifests under `build/`.

For archived or one-off kernel builds under `build/`, pass `--archive-listing`
to `tools/build-i386-kernel.py` to compress the assembly listing after a
successful build. Omit the flag for interactive development when the plain
listing is convenient. For completed, inactive runs, pass the exact
`kernel-assembly.txt` paths to `python3 tools/archive-kernel-listings.py`.
The tool verifies decompression before removing the plain listing and prints
the recovery manifest path. Restore any entry with
`zstd -d ARCHIVE -o SOURCE` using the paths in that manifest.

Keep raw VM working disks sparse. When a test needs an independent writable
copy of a base disk, use `cp --sparse=always --no-preserve=mode -- SOURCE DEST`
with a fresh destination. The native image packager already leaves the unused
tail sparse. Both forms can be passed directly to QEMU.
