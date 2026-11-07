# Normal compile-time source directories

`StreamDir` now resolves the active lexer frame through public `DirFile`, as
`Compiler/CMisc.HC` does. It searches existing directory ancestors rather than
just dropping the final path component, emits nothing when `DirFile` returns
NULL, and keeps an active macro frame when trailing macro tokens remain.
The native frontend supplies the configured temporary filename to macro lexing;
its low-level fallback remains `Frontend` when no file service is installed.
Compiler interface 89 and console interface 250 identify these changes. No new
public export was added; the console table remains 663 entries.

The normal `ExePutS`/`ExeFile` fixture controls cwd and temporarily changes the
contents of the existing public temporary-filename buffer to `Temp/T.HC`, then
restores it. This avoids assuming identical original/native home directories or
changing the public buffer pointer. A marker creates the temporary directory.
The fixture covers existing files and directories, nonexistent suffixes, root
filename and root directory, relative/default source names, `__DIR__`, alias and
trailing-token macro expansion, a cwd change, and nested includes with restored
source context. It checks caller controller/title state and explicitly restores
and verifies cwd after each case.

```
python3 tools/test-i386-stream-directory.py --out OUT-ORIGINAL
python3 tools/test-i386-stream-directory.py IMAGE --out OUT-NATIVE
```

`build/i386-stream-directory-original-v4` and
`build/i386-stream-directory-native-v2` both pass all fourteen words. All fourteen
captured paths match after normalizing only drive letters: 249 bytes, SHA-256
`82f3a9b2cf9a5f3dd93cb56043f8b37c68c289dde98cbcef5cd74f7a497eacb2`.
The native run also checks normal arithmetic pixels, additive fixture packaging,
volume integrity and unchanged inputs. Earlier fixtures, harness failures and
baseline/candidate mismatches remain under `build/i386-stream-directory-*`.

The initial candidate resolved six directory differences but still failed the
default-filename and pending-macro cases. Its source26, Carry and ClassMeta
regressions passed. Its older interactive stream runner timed out before native
startup completed, so that failure establishes no stream-command result. The
runner now allows 900 seconds for TCG startup and selects the current welcome
frame. Its second retained failure was the obsolete pre-welcome initial screen
oracle, also before stream commands. Command/result checks remain intact.
The controlled fixture on the prior console249 image
(`build/i386-stream-directory-baseline-v4`) fails eight observations, including
existing-directory/ancestor resolution and the two temporary-frame cases.

Both x64 bootstrap generations and the full native build pass for the final
candidate `build/i386-stream-directory-cross-v2`; independent source/build-input
audits match the current files. This is source-context progress. Stream failure,
cancellation, ownership, assembly/AOT and normal public compiler delivery still
need qualification; it does not close C1–C5 or qualify another whole application.

Final regressions: `build/i386-stream-directory-source26-v2` passes all 26 stages,
including every earlier contract, sixteen executor observations and nine shared
stream observations. `build/i386-stream-directory-carry-v2` and
`build/i386-stream-directory-classmeta-v2` pass the complete qualified demo
workflows and original document captures. Terminal audits independently verify
all pinned inputs. `build/i386-stream-directory-welcome8-v2` and
`build/i386-stream-directory-diagnostic16-v2` pass the entire 307,200-pixel welcome
oracle. The diagnostic completes both program/code-ownership/file-break phases.
The inventory guard suite passes all five tests; qualification counts stay at
two of 686 whole workflows.

The final interactive rerun `build/i386-stream-directory-legacy-stream-v3`
remains **failed** at the nested include's VGA result: two visible `1` rows are
expected, one is captured. Earlier commands, including generated function and
expression execution and both file writes, pass. Both persisted fixture files
match their submitted bytes exactly; all terminal input pins match. The later
three directory comparisons, cwd reset and retained function call were not
executed by this runner. Its expectation is retained, not reduced to the observed
result. Investigation of this interactive answer-count discrepancy remains open;
the separate normal differential fixture establishes the directory values and
restoration behavior, not this visible-output contract.
