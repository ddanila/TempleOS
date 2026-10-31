# Adam and AdamFile compatibility checkpoint

The original `Adam` and `AdamFile` bodies are shared through
`Kernel/JobAdamCore.HC` and `Adam/DolDoc/AdamFileCore.HC`, and exported by
native ConsoleRuntime 179. The kernel root is the retained `adam_task`: its
main loop now dispatches queued jobs in the root task context and marks itself
idle only after observing an empty queue under interrupt exclusion. Job
submission clears the idle flag. This restores the job path used by `Adam`
rather than substituting execution in the caller's context.

The original-system reference passes the fixture's five checks: formatted
cross-task execution, nested same-task `Adam`, `AdamFile` with default and
explicit extensions, and unchanged caller directory
(`build/i386-adamfile-reference-v2`). The native image passes the same fixture
at 64 MiB and 8 MiB, with unchanged inputs and matching VGA checkpoints
(`build/i386-adamfile-native-v2`, `build/i386-adamfile-native-8m-v1`). These
checks do not cover the warning popup, every job type or full servant and
terminal startup behavior. The concurrent 8 MiB startup is not a timing gate.

Both original bootstrap generations and the full native cross-build/386 audit
pass (`build/i386-adamfile-rebuild-v3.log`,
`build/i386-adamfile-full-cross-v3`). The 16 MiB diagnostic passes its
nine final behavior/VGA checks (`build/i386-adamfile-diagnostics-v1`). The
64 MiB public messaging regression passes all 19 cases with unchanged source
image and matching VGA checkpoints (`build/i386-adamfile-messages-v1`); its
include/clear fixture adds cooperative yields.
The first original fixture incorrectly
omitted escaped percent signs in a nested format and timed out
(`build/i386-adamfile-reference-v1`). The first cross-build rejected an
unsupported macro cleanup (`build/i386-adamfile-full-cross-v1`); moving the
shared bodies after the existing native aliases resolved it. On the earlier
native candidate, the fixture timed out on its first `Adam` call; a traced
run showed the caller was not `adam_task` and stalled before completion
(`build/i386-adamfile-native-v1`, `build/i386-adamfile-native-trace-v2`). The
root loop at that point did not service the root job queue. The corrected
root-loop image passes the comparison above. Full terminal right-click,
autocomplete, application and C1–C5 qualification remain open.
