# Complete original DocLoad

Console 103 compiles the complete original DocLoad body, shared with the
original system through DocLoadCore.HC. The body is unchanged. The new public
binding brings console exports to 255; public layouts, private console services
and Memory 26 are unchanged.

DocLoad inserts into the prepared target instead of resetting it. It clears
filter state, preserves an incoming lock, uses the original DocPutS grammar,
loads binary records, validates/renumbers their references, and applies cursor
position through DocTop/recalculation. This is the contract used by original
undo after undo restoration has detached its queue and prepared the document.
The retained NativeDocRecordLoadCore resets its target and is not substituted
for this operation. Existing DocRead/editor loading is not silently rerouted.

The paired `test-i386-doc-load{,-reference}.py` runners use the same fixture.
Seven cases cover fresh text, insertion after existing text, incoming lock,
null source, plain text containing literal dollar/tab content, a cursor marker,
and an independently constructed binary record. The binary input has a text
reference to bin 7, a 16-byte record header and five known payload bytes. The
oracle requires one linked/renumbered bin 1, its use count and exact payload;
it does not obtain input from the port's serializer.

Each case requires exact first-line text/binary state, current character,
restored incoming lock, cleared filter and unchanged caller put document,
byte-for-byte input preservation, and exact caller heap recovery after disposal
(mask 63). The native runner additively stages a writable image copy and checks
fixture readback and input/tool hashes. Its API prerequisite is rejected on the
previous Console 102 image before integration.

Malformed/truncated input, constructor/admission failures, callback failure,
cancellation and committed Exit remain separate unqualified gates. The original
body trusts record lengths; this checkpoint does not claim validation of hostile
or corrupt document bytes. Nontrivial additional entry/binary combinations still
need coverage.

Original undo also needs the complete serializer/Doc2PlainText path and a clock
with explicit frequency semantics on 386-class CPUs. Do not turn RDTSC into a
386 requirement or treat the retained editor's undo as original undo parity.
Full original DocPutKey and actual chooser input remain open. See PLAN.md for
accepted build and test evidence.

## Accepted evidence

The original control in `build/i386-c4-doc-load-shared-reference` and native run
in `build/i386-c2-doc-load-contract` pass seven masks of 63, with unchanged inputs;
native verifies exact fixture readback and ten commands. The original bootstrap
rebuilds two generations successfully. `build/i386-c2-doc-load-cross` passes its
limited 386 audit, and all 1485 source/build pins match. Clipboard, character/form,
restoration and retained-child Exit regressions pass on this image. Normal
8 MiB startup passes nine checks in 56.68 seconds. These results establish the
listed component contracts, not full document format or original undo parity.
