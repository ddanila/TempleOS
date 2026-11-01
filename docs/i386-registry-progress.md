# i386 registry progress

The original registry cache, default, execution, count, rewrite, append and
initialization bodies are shared with the native console runtime. Native startup
initializes the document command and color definitions in Adam's task, then
runs registry initialization there. The cached registry document is owned by
Adam, as on the original system. Native `DocWrite` uses the public file writer,
so `.Z` documents are compressed and file attributes and resident-file handling
follow the public path.

The shared fixture covers default creation and repetition, execution, rewrite,
append, file-backed lookup and Adam ownership. It returns mask 255 on the pinned
original, the rebuilt original, and native at 8 and 64 MiB with unchanged inputs
(`build/i386-registry-reference-v4`, `build/i386-registry-rebuilt-v2`,
`build/i386-registry-native-v5`, `build/i386-registry-native-8m-v1`). It temporarily directs the cached document to
a disposable writable file and restores the original filename. A separate
native test creates a branch in the real registry, boots the same disposable
image again and executes the saved branch successfully
(`build/i386-registry-reboot-v2`). It does not qualify concurrent registry
access, failure paths, or every original registry API.

The first prototype failed native compilation because it addressed unresolved
forward-declared globals (`build/i386-registry-cross-v1`). Defining the shared
globals before the export table fixed compilation. Native boot then reported
missing `ST_DOC_CMDS` in Adam (`build/i386-registry-native-v3`); initializing
the document definitions in that task fixed startup. The next run returned mask
191 because the raw document writer stored an uncompressed `.Z` file
(`build/i386-registry-native-v4`). The public writer fixed that lookup. The
first cold-reboot test timed out in the driver while typing a wrapped command;
the shortened test completed both boots (`build/i386-registry-reboot-v1`,
`build/i386-registry-reboot-v2`). The original two-generation rebuild, native
cross-build and 386 audit pass (`build/i386-registry-rebuild-v5.log`,
`build/i386-registry-cross-v6`).

The unchanged KeepAway load advances from registry initialization at line 221
to an `Invalid lval` error at `Max` on line 257
(`build/i386-app-keepaway-registry-v1`). Gameplay, the full desktop, and C1–C5
remain incomplete.
