# i386 registry progress

The original-system registry fixture exercises default creation, repeated
initialization, execution, rewrite, append, file-backed tree lookup, and the
registry document's Adam task ownership. On the pinned original it returns the
expected mask 255 with unchanged inputs (`build/i386-registry-reference-v4`).
The fixture temporarily points the cached document at a disposable writable
`B:/RegistryTest.HC.Z` and restores its original filename afterwards. An
initial attempt against the reference system's read-only source medium could
not establish persistence (`build/i386-registry-reference-v3`). These checks
do not establish cold-reboot persistence, concurrent access, or failure paths.

The corresponding native test rejects the missing registry interface on the
last verified DolDoc tree image (`build/i386-registry-native-red-v1`). The
original compiler and kernel rebuild successfully with the proposed extraction
(`build/i386-registry-rebuild-v1.log`), but the native cross-build fails while
referencing `sys_registry_doc` in the export table: the compiler reports
`Feature not implemented` (`build/i386-registry-cross-v1`). The native
registry and the KeepAway workflow therefore remain incomplete.

The inactive patch `docs/patches/i386-registry-prototype.patch.gz` preserves the
prototype for continued work. It extracts the original registry routines,
exports their interface, and attempts to initialize the cache in Adam after
document services start. Use `gzip -dc docs/patches/i386-registry-prototype.patch.gz | git apply` to apply it to this checkpoint. It but has not passed the
native build or runtime tests; it must be repaired and verified before use.
After fixing the compiler error, rerun the native registry fixture and test
cold-reboot persistence and the unchanged KeepAway application.
