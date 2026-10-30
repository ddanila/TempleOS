# Task birth and death waits

The original `BirthWait` and `DeathWait` bodies are shared through
`Kernel/TaskBirthDeathWaitCore.HC` and exported by ConsoleRuntime 145. Their
native dependencies use the existing task validation, cooperative yield,
terminal wait and message paths. `DeathWait` with `send_exit` waits for the
user task's command prompt and sends the original `Exit;` command.

The original and native contracts cover an already-live task, waiting for a
replacement with a different task number, immediate and asynchronous death,
and `send_exit` for a real user task. Both pass with unchanged inputs
(`build/i386-birth-death-wait-reference-v3`,
`build/i386-birth-death-wait-native-v2`). The native fixture writes a completion
marker only after the parent wait returns, because child command logs can
otherwise look like parent completion. The earlier native run lacks that
marker and is not used as sole evidence. Both bootstrap generations and the
cross-build/386 audit pass (`build/rebuild-test`,
`build/i386-birth-death-wait-cross`). The concurrent native run does not
qualify startup timing; task-address reuse and full autocomplete remain open.
