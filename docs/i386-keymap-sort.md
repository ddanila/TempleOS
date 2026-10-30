# Key-map sorting preparation

The original key-map collector sorted a pointer array with `QSortI64`. Its
entries are now explicitly stored in eight-byte slots, retaining the original
64-bit representation while avoiding four-byte pointer slots on i386. The
original comparison functions are shared in `Adam/KeyMapSortCore.HC`.

The pinned and shared original versions produce byte-identical 3,610-byte
output from a live normal/shift key-description collection with controlled key
handlers (`build/i386-keymap-family-original-v4`; runner
`tools/test-i386-keymap-family-original.py`). A separate comparator and sort
fixture checks order, pointer identity and boundary canaries on the pinned
original, shared original and native system (mask 7;
`build/i386-keymap-sort-original-v2`,
`build/i386-keymap-sort-shared-original-v1`,
`build/i386-keymap-sort-native-v2`; runner `tools/test-i386-keymap-sort.py`).
That native fixture compiles the shared comparator directly; it does not execute
the native key-map UI. The initial original fixture cast an array incorrectly and faulted
(`build/i386-keymap-sort-original-v1`); the corrected fixture uses its address.

Both bootstrap generations and the 386 cross-build/audit pass
(`build/keymap-sort-rebuild-v1.log`, `build/i386-keymap-sort-cross-v1`).
These checks do not cover all key descriptions, other modifier families,
concurrent tasks or error cleanup. C1–C5 remain open.
The final image also passes an 8 MiB ordinary-include and drive-fields smoke
check (`build/i386-keymap-sort-smoke-8m`), not a startup-timing or full
minimal-profile qualification.

The native `DocMax` and real single-core `Reboot` services required by the
original key-map UI are now public; see
[document visibility and limits](i386-document-visibility.md) and
[native reboot](i386-reboot.md). The shared original key-map routines and Ctrl-Alt callback setter are now
published on native. The native callback arrays have kernel-lifetime storage.
The controlled public API test covers normal and shifted descriptions, a
registered Ctrl-Alt callback, and a complete `KeyMap` invocation. Physical
Ctrl-Alt dispatch and registration of the original default callbacks remain
unimplemented, so the full original UI remains unqualified. The native export
data bitmap was also enlarged and checked at compile time to cover all exports.

The pinned and shared original public API tests pass (mask 31;
`build/i386-keymap-public-original-v3` and
`build/i386-keymap-public-shared-original-v3`; runner
`tools/test-i386-keymap-public.py`). The same controlled contract passes
on native (`build/i386-keymap-public-native-v2`), with unchanged inputs.

The final native image also passes the 8 MiB ordinary-include and drive-fields
smoke check (`build/i386-keymap-public-smoke-8m`), with unchanged inputs.
