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
attribute. Native lookup and full expansion are being checked; see
[dictionary asset evidence](i386-autocomplete-assets.md). This does not change
the default image or resolve the missing `FOpen` dependency.
