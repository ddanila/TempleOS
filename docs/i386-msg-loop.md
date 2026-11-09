# Unchanged MsgLoop input and output probe

`tools/test-i386-msg-loop.py` runs the byte-identical original
`Demo/MsgLoop.HC` function after loading its source with `CCF_JUST_LOAD`.
A single wrapper holds the setup/program/cleanup compiler statement context.
It uses real GetMsg, actual Print output, QMP key/button/motion events and the
ordinary document insertion path. No message, print or program-body stub is used.
The original source SHA256 is checked against repair revision
`ce055f205fc38536443289fb1cfc73632f6624f4`.

The workflow types `a`, moves the pointer, single-clicks both buttons,
double-clicks left, presses/releases both simultaneously, wheels without a
public wheel message, types `b` with left held, and exits via Escape or
Shift-Escape. Host barriers observe consumed phases. The original returns
`WIG_USER_TASK_DFT`, and caller/document/attribute/heap restoration must be mask7.
Both original variants have exact zero net data-heap use after cleanup.

A read-only document observer counts records without calling DocSave while the
program runs. A private document `user_put_s` callback additionally copies each
original output string and returns FALSE, allowing ordinary insertion to
continue. This captures chronology without sorting or normalizing saved document
entries. An independent model requires the full header and 18/19 exact records,
including full64-bit scan values, button state, coordinates and double-click
codes. The final saved document is captured separately and is still compared
strictly; its insertion order is not used to infer message delivery order.
Screenshots are retained, but complete original pixel equality is not established.

Original references pass at `build/msg-loop-stream-original-v1` and
`build/msg-loop-stream-shift-original-v1`. The full ABI268 candidate fails at
`build/msg-loop-stream-native-v1` and `build/msg-loop-stream-shift-native-v1`.
Both native chronological message-record sequences match the originals exactly,
including mouse bits in both scan halves. Both restore mask7. The native streams
differ only by the missing quoted `msg_code` link in the header. The independent
[source literal probe](i386-document-literal.md) isolates that compiler defect.
No native passing application result is claimed, and failure exits do not assert
a fresh42 or unchanged complete volume snapshot.

Earlier receipts retain actual harness and implementation failures: intrusive
DocSave observation, differing compiler temporary lifetimes across top-level
setup/cleanup statements, missing upper mouse-scan flags, and varying saved
original insertion order. The current stream probe resolves chronology; it does
not establish a stable passing whole-document/raster oracle. Original display
and document insertion differences still require investigation after the quoted
source repair. Do not discard/reorder document entries or accept record counts
as full application qualification.

Qualification remains2/686. This workflow does not cover every key, initial
mouse setting, pending-input/loss/focus/callback permutation or complete
original desktop/resource/native self-hosting behavior required by C1–C5.

The shared serializer repair fixes the header in both native variants:
`msg-loop-literal-native-v1` and `msg-loop-literal-shift-native-v1` match the
complete original chronological streams and restore mask7. They still fail
strict saved-document equality, so no application qualification is added. See
[serialization evidence](i386-document-serialization.md).
