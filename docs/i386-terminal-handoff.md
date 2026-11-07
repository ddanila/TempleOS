# Existing-document handoff to UserTaskCont

A servant can print output and then call `UserTaskCont` to make that same
window interactive. Two native gaps prevented this original workflow:

- The default `SrvStartUp` was defined only in the initial console. Detached
  servants inherit Adam, so they had neither the original terminal documents
  nor the original non-raw output state before running their commands.
- UserTaskCont created an empty document when no native terminal instance
  existed, replacing any supplied put/display document instead of continuing it.

The file-search wizard exposes the combination when it calls Find followed by
UserTaskCont in a detached result task.

Normal startup now loads the complete original `Adam/SrvStartUpCore.HC` in
Adam using AdamFile and verifies the executable binding. SrvCmdLine's dynamic
lookup remains unchanged, including caller overrides. This fixes the scope
where the default is published instead of introducing a fallback implementation.

The terminal change lets native terminal creation borrow the existing `DocPut` for this
handoff. Borrowing preserves all document-role pointers and text attributes,
starts with the existing transcript, and uses document rendering. Allocation
failure and terminal cleanup delete only documents the terminal allocated.
Closing a child must not delete a document belonging to its caller. Ordinary
new-terminal and root creation continue to allocate their own documents.

`tools/test-i386-terminal-handoff.py` uses actual asynchronous `PopUp` execution.
The child prints a sentinel and rich document link, records its three document
pointers and calls UserTaskCont. The parent observes the interactive prompt and
checks pointer identity and content. The host executes `6*7`, checks rendered
42, and closes the child with Shift-Esc. Caller roles must survive.

The second case supplies a caller-owned document to the child and checks that
its sentinel/link still exist after child retirement, before the owner deletes
it. This explicitly exercises borrowing rather than silently transferring
ownership to terminal cleanup.

The initial original control (`build/i386-terminal-handoff-original-v1`) passes
mask 31. The old native control (`build/i386-terminal-handoff-native-baseline-v1`)
returns 20: border identity and caller restoration pass; put/display identity
and sentinel/link preservation fail. Arithmetic and normal closure still work,
so those alone would hide the lost output. Both retain frozen fixtures and
runners. The expanded original v2 control passes masks `[31,63]`.

Run the current two-case contract with:

```sh
python3 tools/test-i386-terminal-handoff.py --out OUT
python3 tools/test-i386-terminal-handoff.py IMAGE --out OUT
```

This does not qualify the full original terminal loop. Prompt formatting,
command-result formatting, editing/history, exception recovery, borrowed-document
allocation-failure injection, heap balance and visual equivalence remain
separate requirements. Full C2/C4/C5 qualification remains open.

The expanded baseline v2 observed the same identity loss in both cases, then
hit `DocGone` when the fixture read its borrowed document while `win_task`
still named the retired child. The final fixture first lets the surviving
owner reclaim `win_task`, then reads and deletes its document. This preserves
the native lifetime check instead of bypassing it. The original v3 control
passes `[31,63]` with this ordering. Baseline v2 remains frozen as a fixture
lifetime failure, not a completed two-case compatibility result.

The document-borrowing-only image (`build/i386-terminal-handoff-cross-v1`)
passes its 8 MiB welcome and 16 MiB diagnostics but still fails the workflow:
`build/i386-terminal-handoff-native-v1` returns `[20,23]` and the wizard v3
still cannot find retained search results. The supplied document's identity
now survives, but without shared SrvStartUp the detached task is still raw
and its initial output is absent. This is not a qualified handoff image.

A diagnostic candidate (`build/i386-terminal-handoff-adam-candidate-v1`)
loads the delivered original startup in Adam before executing the same
contract. It passes `[31,63]`, including actual arithmetic and borrowed-document
survival. Normal-boot verification must use the subsequent image containing
the startup publication change, without this test-only setup.

The normal-boot handoff comparison `build/i386-terminal-handoff-native-v2`
passes `[31,63]` on `build/i386-terminal-handoff-cross-v2/kernel.img`, without
test-only startup loading. Both saved documents retain the exact sentinel and
rich-link serialization; the mask bytes match the original v3 control. The
terminal audit independently verifies test/image hashes, all preexisting file
tuples and the fixture addition, as well as actual child and caller arithmetic.

`build/i386-servant-hook-handoff-v1` also passes the existing startup-override
contract: the original startup body is interposed and called exactly once after
inhibit initialization, ten servant jobs return 42 with correct completion and
idle/title/ring state, and the original hook is restored. Its independent
filesystem and input audit passes. This guards the dynamic override lookup
while the default moves into Adam's shared scope.

The preserved handoff documents still differ from the original terminal's
command-result and current-directory prompt formatting. Their exact sentinel
and link match; full document or pixel equivalence is not claimed.

## Build and regression evidence

The final image is `build/i386-terminal-handoff-cross-v2`, built from the
preserved passing two-generation bootstrap
`build/rebuild-terminal-handoff-v2-verified`. All 1,737 production source
hashes match before and after native export. The 386 audit passes 96 BIOS and
332 protected-mode instructions. No public ABI or service version changes.

The final 8 MiB normal welcome and full 16 MiB diagnostics pass exact 307,200
pixel comparisons. Both program-probe, code-heap-ownership and file-break-cleanup
phases complete; `diagnostic16-audit.json` revalidates all source hashes. These
are concurrent functional checks, not isolated timing or C5 installed native
generation qualification.

The earlier document-borrowing-only image passes the two-terminal regression
at `build/i386-terminals-handoff-v2`: independent definitions/history, focus,
exit refocus, child reclamation and exact parent public-heap recovery. Its
terminal audit rechecks the checker and disk hashes and the passing exact-VGA
result. This does not qualify the later shared-startup image.

The final shared-startup image also passes at
`build/i386-terminals-handoff-v3`: eleven commands after setup, all exact-VGA
checkpoints, independent definitions/history, focus, child exit/reclamation and
exact parent public-heap recovery. Its terminal audit rechecks the checker and
disk hashes; the source image is unchanged. Both runs are now terminal. The
initial v1 attempt ended before guest execution because another boot check held
the source disk's write lock. Both actual runs used independently verified copies.
Process commands remain in `build/terminal-handoff-verification-processes.json`.

The missing original answer and directory prompt now has a direct six-case
reference contract; see [command prompt](i386-command-prompt.md). Restoring the
original prompt and public interactive lexer remains separate from document
handoff and terminal ownership.
