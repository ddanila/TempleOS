# Original serialization in native quoted source

Native compilation now preserves quoted document metadata using the original
`Doc2PlainText` serializer and dollar escaping. Previously
`Compiler/I386/LexInput.HC` reconstructed a short formatting whitelist and
silently skipped links and other metadata. This dropped MsgLoop's header link.

`I386LexEntryDollar` follows original `LexGetChar` selection: ordinary text keeps
its tag while special text metadata is serialized; newlines, tabs and binary
entries keep their token rules; cursor/marker entries are skipped; script offsets
retain their outside-quote behavior. Other quoted entries use the formatter.
The existing scalar bootstrap path remains available without the full document
runtime; unsupported quoted metadata now fails instead of disappearing.

The retained Console provider calls the shared original serializer and
`MStrPrint("$$%$$Q$$",plain)`, copies the result to the requesting compiler heap,
and frees its public temporary strings. The compiler owns `cc->dollar_buf` and
releases it through its existing control lifetime. The provider requires an
initialized document dictionary. The versioned file-document registration hook
installs it for both document roots and nested includes; disabling the hook
clears it. Provider code is retained for the boot's lifetime.

Compiler ABI105, File ABI66 and Console ABI269 version the behavior/interface.
The kernel adds its private formatter-registration binding. No snapshot/file
record layout or public original document-source API is replaced.

`tools/test-i386-document-dollar-matrix.py` compares 35 cases through actual
nested includes and original `ExeDoc` roots, plus one constructed root CLEAR
entry: 71 exact byte results including NUL. Cases include ordinary/special text,
links/anchors, buttons, an inline checkbox, tree/cursor movement, quote/dollar
escaping, colors/layout/script controls, skipped markers/cursors, newline/tab,
and a 1200-character link label. The constructed CLEAR source is not recalculated
before compilation: an unescaped CLEAR in a loaded source file deletes preceding
source in the original and is not a valid combined-file fixture.

The original reference is `build/document-dollar-matrix-original-v8`; the
candidate passes at `document-dollar-matrix-native-v5`. The prior ABI268 image
fails the same probe at `document-dollar-matrix-native-before-v3`. The simpler
two-case literal probe also passes at `document-literal-native-v1`, including its
independent original expectations. The audit checks every paired payload-byte
corruption against the original and the independently expected CLEAR output.

The bare control test adds eight formatter binding/ownership cases across both
IRQ states: borrowed roots, owned includes, 1025-byte callback buffers,
allocation failure and unbound rejection. It exercises the actual raw reader
and control destructor and requires zero arena allocations/usage plus valid
heap state. Its callback supplies a test payload; real serialization is checked
by the preceding original/native matrix. The test links the real emitter chunk
release implementation, not a release stub. See
`build/document-literal-lex-control-v2`, `-lex-state-v1` and `-lex-snapshot-v1`.
This does not establish arbitrary snapshots inside formatter buffers or actual
serializer OOM/cancellation behavior.

The new error-path probe passes at `document-dollar-cleanup-native-v4`: three
formatted-source syntax errors before code generation restore exact caller
data/code heaps, put document, compiler boundary and IF, followed by a successful
literal4 command (mask127). Diagnostic documents are captured and freed before
measurement. Its original ordinary baseline passes mask7 at
`document-dollar-cleanup-original-v4`. An earlier zero-heap expectation for
successfully executed string statements was invalid: `CCF_HAS_MISC_DATA` can
intentionally retain code/data for string lifetime. That failure is retained;
the implementation was not changed to discard that data.

Existing binary include, AOT and compiler-error recovery probes pass in
`document-literal-include-v2`, `document-literal-aot-v2` and
`document-literal-cleanup-v2`. Their drivers now accept a native accelerator
option with the previous TCG default. Earlier TCG runs timed out during startup,
before assertions; KVM runs retain the same assertions and 486,-fpu model.
Calibration failures/interruption explanations remain under `build/`, including
invalid source commands, the original ExeDoc API correction, dollar escaping,
and the checkbox flag correction (D means define; P controls dereferencing).

The full image is `build/i386-document-literal-cross-v1/kernel.img`, pinning 1860
sources and 26 helpers. Two source-matching classic bootstrap generations and
the 386 instruction audit pass. Kernel/CompilerRuntime/CompilerProbe/FileRuntime/
ConsoleRuntime change; the other eleven modules match the prior image. The bare
kernel is 458680 bytes. A single-job normal 8 MiB KVM 486,-fpu startup reaches
live WinMgr and exact welcome/42 pixels in 53.610 seconds, with no other QEMU
process at invocation. This is the current normal 60-second baseline subgate,
not full original-desktop/all-app/resource C5 acceptance or native generations.

Both unchanged MsgLoop chronological streams now match the original byte for
byte, including the header, all 18/19 message records and mask7 restoration.
Their saved documents still differ in insertion order/cursor state:
`msg-loop-literal-native-v1` and `msg-loop-literal-shift-native-v1` remain strict
failures. No application or additional inventory file is qualified. Qualification
stays 2/686; complete document/raster/resource behavior, OOM/cancellation,
formatted snapshot permutations, remaining applications and C1–C5 remain open.
