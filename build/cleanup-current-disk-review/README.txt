Disk review and lossless cleanup

Work stayed on main. Existing unfinished source changes were excluded.

manifest.jsonl records disk images whose allocated zero ranges were converted
to sparse holes with fallocate --dig-holes. Complete SHA-256 and file length
were verified unchanged after every operation; no restoration is necessary.

assembly/manifest.json records historical assembly listings compressed using
zstd, with decompressed SHA-256 verified before removing the redundant raw
copy. Each record contains an exact restore command. Current cross-v5 assembly
and the earlier explicitly retained canonical listings were excluded.

No unique build/test evidence, source files, caches, downloads, or other
projects were deleted. AGENTS.md already records direct main/master workflow.
