# Document key input

`Adam/DolDoc/DocGetKeyCore.HC` shares the original EdUndoFilter and DocGetKey
bodies between the original DolDoc module and native console. The key-descriptor
inhibit bit is defined once in `Kernel/KeyDescFlag.HH`, included by both systems.
Console interface 78 adds the public `_DOC_GET_KEY` binding.

DocGetKey temporarily allows key descriptors, obtains echoed keys until it
receives a non-descriptor, restores the caller's inhibition bit, and recalculates
the output document. Esc or Shift-Esc in filter mode clears the per-entry
FILTER_SKIP flags and filter_lines counter, then continues reading. Otherwise
it returns the character and optional scan code. It uses the existing shared
GetKey and document recalculation rather than introducing a separate input
buffer.

## Reference contract

```
python3 tools/test-i386-doc-getkey-reference.py --out build/FRESH-original
python3 tools/test-i386-doc-getkey-reference.py --current-system --out build/FRESH-control
python3 tools/test-i386-doc-getkey.py IMAGE --out build/FRESH-native
```

The pinned original passes (`build/i386-c1-doc-getkey-reference/result.json`).
The extracted implementation passes on the freshly rebuilt original system
(`build/i386-c4-doc-getkey-shared-reference/result.json`). Both produce this
explicit 14-field signed-I64 oracle:

```
97, 30, 2, 1, 0, 1, 98, 0, 72, 113, 1, 114, 1, 8
```

The fields cover character/scan return, two echoes including a discarded
descriptor, descriptor observation, cleared inhibition during callback and
restoration afterwards, null scan pointer, zero-character delivery, both
filter-exit keys, complete filter/lock clearing and total echo count. A consuming
priority-10 hook isolates echo observations from default document editing.

Before the binding, the native test rejects its DocGetKey caller with an
`Invalid lval` compiler error at DocGetKey
(`build/i386-c4-doc-getkey-red/result.json`). This demonstrates an unavailable
public API; it is not a native runtime qualification.

Bootstrap rebuild, native cross-build and 386 boot instruction audit pass
(`build/i386-c4-doc-getkey-cross`). The 8 MiB startup regression passes in
47.08 seconds with zero build-provider loads
(`build/i386-c4-doc-getkey-startup/result.json`).

The native public API passes the full 14-field byte comparison across 12
commands on `486,-fpu` at 64 MiB
(`build/i386-c4-doc-getkey-native/result.json`). Both filter exit cases leave
the document unlocked and all observed filter flags clear. This supersedes the
missing-API gate for these cases.

## Remaining qualification

Default document echo/rendering, physical input through DocGetKey, callback
exceptions and inhibition restoration on unwind remain open. The shared body
retains the original normal-path policy; it has no new exception-restoration
wrapper. These tests do not qualify GetStr, navigation/replay, all filter states
or the complete DocGet.HC inventory item.
