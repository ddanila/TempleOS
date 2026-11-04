# Autocomplete dictionary workflow

The reference runs the unchanged original autocomplete implementation with the
pinned 1,253,930-byte word list and 26,381,073-byte definitions. It uses the
previously qualified original-system word archive, added before startup so the
normal asset-presence checks see the compressed word file. The dictionary-only
ACInit default is exercised; source-statistics traversal is a separate workflow.

The rebuilt original loads 95,293 words, creates the actual autocomplete task,
accounts its owned dictionary allocations, retrieves definitions, stops the
task, reinitializes the full dictionary and stops the new task. The second task
must have a new task number and the same word count and word-list byte length.
A captured task handle is retained for DeathWait during shutdown, since the
application's end callback clears its global task pointer.

The 5,270-byte report includes first and second definitions and the complete
binary ACDDefsGet records for Apple, Temple and Computer. These records contain
internal NULs; their lengths come from the record protocol, not StrLen. A missing
word must return NULL. An independent host decoder walks every pinned word-list
record, validates block indexes, finds the three definitions in the source
asset, decodes all their fields and reconstructs the entire expected report.
It confirms 5, 8 and 1 definitions respectively, with complete record sizes
2,891, 1,758 and 51 bytes.

The reference passes with unchanged inputs at
`build/i386-autocomplete-dictionary-reference-v8/result.json`.
The earlier v5 report has the same bytes and an independent asset audit.
Reference report SHA-256:
`b8aa0b9b6175c16652c705c2fe3c2ce5b778c4e10d9b5bcc5b2cb8b278279fdd`.
Original allocation accounting is 9,527,728 bytes; allocator sizes may differ
between architectures and are not used as a cross-architecture byte oracle.

Native root-context loading initially rejected __DIR__ although the same source
loaded from the user console. PublicUser.HH omitted PublicStream.HH, which
supplies the existing StreamDir-backed compile-time macro. The common header
set now includes it, providing that real service to root jobs and servants as
well as user tasks. The library and fixture load through actual AdamFile jobs;
application source and runtime services are not replaced. The updated image
(`build/i386-autocomplete-dictionary-cross-v3`) passes two original rebuild
generations, the 386 audit and all 1,260 delivered-source checks. Native
root-context loading and initialization now execute; dictionary comparison
still fails. A second
root-context failure at ACTask line 104 was a call to StrCmp without its typed
declaration: that declaration existed only in user StartOS. PublicFormat now
publishes the real resident StrCmp signature, and StartOS uses the inherited
declaration. The next run reaches ACInit but rejects its try/catch because
SysTry and SysUntry likewise existed only in user startup. PublicDebug now
publishes those resident signatures and throw, and StartOS uses all inherited
common declarations. No compiler member-access change was needed.

Earlier fixture attempts remain failures: the first export command had nested
format escaping, subsequent root file compilation used unsupported conditional
expressions, and a string-only report omitted binary record tails. A final
fixture-loaded marker proves the entire root file compiled before execution.
The complete binary report and independent decoder replace those weak checks.

This workflow does not qualify visible suggestions, function-key selection,
source word statistics, exact application heap recovery, parent-terminal closure,
8 MiB resource gates, full desktop operation or C1-C5 completion.


Native attempts v4-v6 load the unchanged library and complete fixture in Adam,
initialize all 95,293 words from the 1,253,930-byte word list, and start the real
autocomplete task. Native owned dictionary accounting reports 8,355,320 bytes.
These are observations within failed contracts, not complete workflow passes.
The first definition lookup fails: both getters return NULL while ACDWordPtAt
finds Apple correctly. In v6, a direct HashFind returns the Apple entry with
block index 66; FOpen reports the correct 26,381,073-byte definitions file;
FBlkRead succeeds and finds Apple at byte 16,047 of the two-block window, with
matching initial bytes. The original v8 diagnostic reports the same index,
file size, read result and record offset and passes the complete lifecycle.

A separate one-entry native search diagnostic successfully calls the unchanged
getter and a traced copy against the actual definitions file. This is a reduced
diagnostic with manually constructed index state, not application qualification.
The difference after full initialization remains under investigation. Native
exact definition bytes and stop/restart are still unqualified. Historical native
v1-v3 failed root loading at __DIR__, StrCmp and exception helpers respectively;
the common declarations resolve those source-context failures.

Further reduced diagnostics narrow the failure without qualifying the contract.
The unchanged getter and a traced copy both return a definition immediately after
full ACInit in one Adam command (`build/i386-acd-search-diagnostic-v4`). The full
report also succeeds with a three-entry diagnostic index and the pinned word list
(`build/i386-acd-search-diagnostic-v5`); that constructed index is not a substitute
for initialization. With the actual contract's initialization in a preceding Adam
command, the next diagnostic's first getter succeeds, but the traced second call
cannot open the file and the report's direct FOpen also returns NULL
(`build/i386-acd-search-diagnostic-v6`). Thus a compiled-search or caller-only
explanation is not established. Repeated file opening with the live task is the
next investigation. The native channel explicitly rejects a contended root
acquisition, and the existing ATA task test expects that behavior; contention is
a candidate cause, not yet a confirmed explanation for this application failure.
