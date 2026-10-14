# Native output-hook dispatch and ScanKey

The original PutKey/PutS/PutChars and KeyDevAdd/KeyDevRem bodies are shared
through `Kernel/KeyDevOutputCore.HC`. Canonical entry/global records and scan
flags are shared headers used by the original kernel and native public headers.
The platform adapter supplies the keyboard scan-state value and root-owned
allocation; Scroll Lock waiting uses the managed Yield service.

Native compiled text and packed-character output now enter the same hook chain.
Console interface 75 exposes PutKey, KeyDevAdd, KeyDevRem and ScanKey. ScanKey
uses the original shared body, with ScanMsg delegated to the managed message
service and echo delegated through the real PutKey hook chain. Hooks are
registered once for input-filter message output and the console sink.

## Original dispatch oracle

`tools/test-i386-keydev-reference.py` records twelve I64 traces (96 bytes), with
callbacks identified by digits. Pinned original and rebuilt x64 control runs
pass identical explicit expectations in `build/i386-c1-keydev-reference` and
`build/i386-c4-keydev-shared-control`.

| Operation | Trace |
| --- | --- |
| Ordinary key with hooks at priorities 10, 20, 30 | 321 |
| Descriptor key, only middle hook accepts descriptors | 2 |
| Two-character PutS: high hook fallback, middle string callback, low fallback | 33511 |
| Silent key/string output | 0 / 0 |
| Packed characters with an embedded zero byte | 321321 |
| Zero key and NULL string | 0 / 0 |
| Same-priority replacement | New hook only: 4 |
| Replacement string callback consumes output | 6 |
| Descriptor skips replacement lacking descriptor flag | 2 |
| Remove replacement, dispatch remaining hooks | 21 |

The numeric ordering is ascending; descriptions of the earlier I64_MAX echo
probe as highest-priority do not establish first dispatch. In particular, PutS
fallback finishes the current hook's character loop even after a character is
consumed, then stops descending the chain. These observed rules are retained
by sharing the original code rather than rewriting the loop.

## Native evidence and boundaries

The preceding native image rejects the new fixture at missing CKeyDevEntry /
public hook declarations (`build/i386-c4-keydev-red`). The first integrated
candidate exposed a default-console descriptor issue: a descriptor could reach
the sink and be drawn as an ordinary character. The final sink ignores
descriptor events and does not draw Ctrl/Alt shortcut characters. This does not
implement the original descriptor-description UI.

The fixed native fixture passes all twelve traces through public interfaces in
`build/i386-c4-keydev-fixed-native/result.json`. The public ScanKey component
check uses real KeyDev registration and message delivery rather than a renamed
primitive/test echo alias. Its 24-field matrix covers empty output reset,
zero-character/null-pointer cases, mask discard, echo arguments and descriptor
allow/inhibit behavior. GetKey waiting remains a different, unbound API.

The default string sink currently retains the existing plain console recording
and projection. Original DocPrintPartial streaming, full default document/raw
output, descriptor descriptions, Ctrl-Alt callbacks, scroll-wait qualification
and callback lifetime/error cases remain open. Those are required compatibility
work, not excluded scope. This checkpoint qualifies the shared dispatch rules
and published nonblocking key primitive, not complete standard I/O or C1–C5.

## Final candidate verification

The final source bootstraps twice and passes the cross-build/386 audit in
`build/i386-c4-keydev-fixed-cross`. Public output-hook testing passes twelve
traces in `build/i386-c4-keydev-fixed-native/result.json`. The public ScanKey
matrix passes 24 fields in `build/i386-c4-scan-key-public-final/result.json`;
this mode uses an actual registered echo hook, not the shared-core test alias.
The existing two-terminal and thirteen-command transcript suites pass in
`build/i386-c4-keydev-terminals-final` and `-transcript-final`. The final
nine-command 8 MiB startup gate passes in 44.6276 seconds with no build-provider
loads (`build/i386-c4-keydev-fixed-startup/result.json`).

The full public input suite advances past the initial ScanKey helper/check and
rejects the KeyRead helper at GetKey in
`build/i386-c4-keydev-getkey-red/result.json`. The later 28-field collection is
not executed. No complete GetKey/GetStr, standard-I/O or release qualification
is claimed. Full native-generation coverage and the prior background-memory
regression remain separate gates.
