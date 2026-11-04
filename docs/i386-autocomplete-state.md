# Autocomplete state and source gate

The original autocomplete hash entry, state and dictionary records are shared
through `Kernel/AutoCompleteHashTypes.HH` and `Kernel/AutoCompleteTypes.HH`.
ConsoleRuntime 146 exports actual `ac` and `acd` storage, initially zeroed;
this supplies the original state objects but does not initialize a dictionary,
start the autocomplete task, or implement suggestions.

The original and native state fixture checks local record fields, pointer
arrays and the exported global bindings. The updated original and native checks pass with unchanged inputs
(`build/i386-autocomplete-state-reference-v2`,
`build/i386-autocomplete-state-native-v2`); the concurrent native run does not
qualify startup timing. Both original bootstrap
generations and the cross-build/386 audit pass (`build/rebuild-test`,
`build/i386-autocomplete-state-cross`). The preceding native fixture also
passes, but did not explicitly read the global contents.

The unchanged source load initially rejects the missing `ac` binding
(`build/i386-autocomplete-native-load-v1`). With the state exported, it
advances to the missing `FOpen` at `ACFill.HC` line 11
(`build/i386-autocomplete-native-load-v2`). The source files match the pinned
original, but the native image lacks the original `ACWords.DATA` and
`ACDefs.DATA` assets. Loading, initialization, dictionary storage, the visible
autocomplete task and complete settings behavior remain open; no C1–C5
milestone is qualified by this checkpoint.

The full original block-backed file-stream bodies and a ten-check original
reference are now available for the `FOpen` dependency. The native stream
fixture still rejects before execution; see [file stream evidence](i386-cfile-stream.md).

A separate 64 MiB disk candidate now packages both pinned dictionary assets,
including an original-system-compressed word archive with the proper RedSea
attribute. Native lookup and full expansion pass with byte-identical readback; see
[dictionary asset evidence](i386-autocomplete-assets.md). This does not change
the default image or resolve the missing `FOpen` dependency.

On the current image the unchanged loader still rejects `FOpen`
(`build/i386-autocomplete-native-current-v1`). A compile-only diagnostic with
explicitly throwing stream functions advances past that dependency: before the
case-insensitive comparison binding it rejects `StrICmp`
(`build/i386-autocomplete-stream-probe-v1`), and after that binding it reaches
`ACTask.HC` line 32, immediately after the unbound `DocCursor` call
(`build/i386-autocomplete-stream-probe-v2`). These test providers cannot perform
file I/O; neither diagnostic establishes autocomplete behavior. See
[case-insensitive comparisons](i386-string-comparisons.md).

After publishing `DocCursor` and the related document visibility controls,
the same compile-only stream probe gets past that call and rejects the missing
`tS` public binding at `ACTask.HC` line 89
(`build/i386-autocomplete-stream-probe-v3`). The probe's stream functions
still throw if called, so this does not implement or qualify autocomplete.
See [document visibility controls](i386-document-visibility.md).

After publishing `tS`, the same diagnostic advances to the unbound
`KeyMapFamily` call in `ACTask.HC` line 180
(`build/i386-autocomplete-stream-probe-v4`). It still uses deliberately
throwing stream providers; the real `FOpen` dependency and autocomplete
execution remain unimplemented. See [elapsed seconds](i386-elapsed-seconds.md).

The original scan-code conversion and naming services required by key maps
are now public on native and have an exhaustive bounded differential fixture;
see [scan translation](i386-scan-translation.md). The compile-only stream
probe still stops at `KeyMapFamily` on `ACTask.HC` line 180
(`build/i386-autocomplete-scan-translation-probe-v1`). The key-map routines
need their remaining dependencies and careful pointer-width handling: their
original pointer array is sorted as 64-bit slots. Real streams and autocomplete
remain open.

Key-map labels now use explicit eight-byte sorting slots and have an original
live-output comparison and a native comparator fixture. The UI and its
remaining providers are still unbound; see [key-map sorting](i386-keymap-sort.md).
The native substring and bounded string comparison APIs needed by that code are
also available; see [string comparisons](i386-string-comparisons.md).

The key-map public routines are now bound; a compile-only diagnostic advances
to the unbound `DocTermNew` call in `ACTask.HC` line 221
(`build/i386-autocomplete-keymap-probe-v1`). The diagnostic uses deliberately
throwing stream providers and does not qualify autocomplete execution. See
[key-map sorting](i386-keymap-sort.md).

The welcome-console full-content image repeats this boundary
(`build/i386-c1c5-welcome-autocomplete-compile-probe-v1/result.json`): the
unchanged autocomplete sources reject with an undefined identifier at
`ACTask.HC` line 222, immediately after `DocTermNew`. All pinned probe inputs
remain unchanged. The shared `Adam/DolDoc/DocTermNewCore.HC` body exists but
is not exposed by the native image. This compile probe still supplies throwing
stream providers and establishes neither real stream nor autocomplete behavior.

Compiling the original terminal right-click callback separately on that image
stops earlier than its mounting branch: `Copy` at line 40 is not bound in the
native public file API
(`build/i386-terminal-constructor-dependency-probe-v1/result.json`). The guest
reports `Invalid lval` at token `Copy`; the source image hash remains unchanged.
No callback executes. Completing `DocTermNew` therefore also requires the
original copy workflow and subsequent callback dependencies, rather than only
publishing the constructor.


The stream and copy dependencies are now actual retained native services; see
`docs/i386-cfile-stream.md` and `docs/i386-copy-single-z.md`. The autocomplete
compile probe no longer supplies throwing FOpen/FBlkRead/FClose replacements.
Loading the unchanged MakeAC source against real services still rejects at
ACTask.HC line 222, immediately after the missing DocTermNew
(`build/i386-copy-autocomplete-real-probe-v1`, inputs unchanged). No explicit
autocomplete task activation is requested or qualified. The unchanged terminal
right-click callback now advances past real Copy/Move/Del to missing MountFile
at line 76 (`build/i386-copy-terminal-callback-probe-v1`). These are current
dependency boundaries, not autocomplete or terminal-construction passes.


The complete MountFile and mapped media services now close that callback's
compile dependency. Both the unchanged right-click callback and complete
DocTermNew body compile against actual native services
(`build/i386-mount-terminal-constructor-probe-v1/result.json`). No constructor or
menu action executes in this probe. Global DocTermNew publication and real-service
autocomplete execution remain open; the full original constructor/callback body
must be preserved when integrated.


DocTermNew is now a resident public binding. Its complete original constructor
and right-click callback bodies are retained; paired original/native constructor
execution passes mask 1023 with actual border/menu/scroll services. See
`docs/i386-terminal-constructor.md`. The unchanged MakeAC real-service probe
now rejects at missing KbdMsEvtTime (ACTask.HC line 230,
`build/i386-terminal-constructor-autocomplete-v1`), with unchanged input pins.
Autocomplete execution and visible suggestions remain unqualified.


The original KbdMsEvtTime body and complete CKbdStateGlbls layout are now shared
and bound to actual native raw input timestamps and scheduled key state. The
original timing-decision cases and native hardware key/mouse contract pass;
see `docs/i386-input-event-time.md`. The unchanged MakeAC probe advances past
both timing and kbd.scan_code and now rejects missing sys_run_level at ACTask.HC
line 265 (`build/i386-input-event-time-autocomplete-v1`, unchanged input pins).
No autocomplete task activation, initialization or visible suggestion behavior
is qualified by that failed source-load probe.


The shared kernel-owned U32 sys_run_level is now public. Actual readiness stages
and cross-task reads/writes pass the native 64 MiB contract; the original reference
and thirteen raw-output vectors pass too. See `docs/i386-run-level.md` for lifecycle
differences and the still-failed 8 MiB full-contract compilation. The unchanged
MakeAC probe now rejects missing Size at ACInit.HC line 116
(`build/i386-run-level-autocomplete-v2`, unchanged input pins). No explicit
autocomplete initialization or task activation is qualified.


The complete original Size/Size1, ScanFlags and file-utility flag initializer
are now retained. Paired original/native contracts pass fourteen size cases and
flag-parser mask 31, including compression, recursion, 64-bit rounding and heap
recovery. See `docs/i386-file-size.md`. The unchanged MakeAC source now rejects
missing HashTableSize2 at ACInit.HC line 166
(`build/i386-file-size-autocomplete-v1`, unchanged input pins). No explicit
autocomplete initialization, task activation or visible suggestion workflow is
qualified by the failed source-load probe.


The complete original hash accounting dependency is now retained: linked lists,
member lists, entries and tables, with all original type branches and exclusions.
Eighteen owned-record cases pass against allocator ledgers on original/native
systems; see `docs/i386-hash-memory.md`. The unchanged MakeAC source loads
successfully against real services (`build/i386-hash-memory-autocomplete-v1`,
inputs unchanged), followed by resumed command execution. This closes the source
load gate; initialization, actual dictionary access and visible task workflows
remain unqualified by that gate alone.


The rebuilt-original dictionary workflow now passes actual initialization,
95,293 indexed words, exact binary definition records and autocomplete task
stop/restart. An independent pinned-asset decoder reconstructs its full report.
Native root-context qualification is tracked separately in
[the dictionary workflow](i386-autocomplete-dictionary.md); the user-console
source-load pass alone does not cover that context.


The native dictionary contract now passes too: actual Adam loading, both 95,293-word
initializations, exact binary definitions with independent pinned-asset decoding,
and task stop/restart. Root ATA requests now wait in FIFO order under contention
instead of returning failure. The full ATA task regression passes with exact
commands and backing images. See [root I/O waiting](i386-root-io-wait.md) and
[the dictionary workflow](i386-autocomplete-dictionary.md). Visible suggestions,
function-key selection, source statistics and complete C1-C5 qualification remain
open.
