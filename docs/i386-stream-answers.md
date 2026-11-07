# Pending answers from compile-time execution

The normal native frontend executed `#exe` statements but discarded their task
answer state. A file containing `Cd(__DIR__)` and later directory macros could
therefore present an earlier Cd result, although original StreamDir execution
left a pending void result. This was the one-row/two-row discrepancy retained in
`build/i386-stream-directory-legacy-stream-v3`: the old expectation of two Cd
answers was wrong, and the native single Cd answer was also wrong.

Compiler interface 90 shares `I386FrontendExecuteAnswer` between ordinary command
execution and the compile-time statement executor. Both record value, raw type,
pointer depth, elapsed time and `new_answer` using the normal input's clock and
context. Pointer depth is copied before nested execution can retire metadata;
no class pointer is retained. Compile-time results update task state without
calling the outer answer callback, preserving ExePutS's separate return value.
Low-level frontends without an execution clock
retain their previous behavior. Public layouts/exports and console250's 663
entries are unchanged. This change does not qualify every compiler execution mode.

## Original differential prompt fixture

```
python3 tools/test-i386-answer-prompt-reference.py --out OUT-ORIGINAL
python3 tools/test-i386-answer-prompt-reference.py IMAGE --out OUT-NATIVE
```

The fixture uses real ExePutS and CmdLinePmt with queued GetStr input, captures
all documents before/after prompt consumption, and records six task observations
per case. It preserves the previous nine cases: final scalar/include/void,
explicit output, nested ExeDoc, caught syntax rejection and nested initializer
integer/F64/pointer answers. Eight additions cover the exact nested-directory
include and bare integer/F64/pointer compile-time blocks, plus the same blocks
following a runtime expression and a compile-time counter assignment verified
to execute exactly once.

`build/i386-answer-prompt-reference-stream-v4` and
`build/i386-answer-prompt-native-stream-v3` pass all seventeen cases (102 words),
with independently verified input pins. These are semantic comparisons, not
claims of identical raw buffers: void pre-prompt values and timing are not
stable, and the original x87 F64 value may be one ULP above 3.75. The oracle
checks categories, pending/consumed flags, returns and exact answer text. The
native run also checks arithmetic pixels, additive packaging and volume integrity.

The original nested directory include prints no automatic scalar during
execution. Its final directory macro leaves a pending U0 answer; CmdLinePmt
prints a timing line, clears the answer to zero and consumes `new_answer`.
A bare block leaves 123, 3.75 or a NULL pointer pending. In `7;#exe{123;}`,
lookahead executes the block during compilation before the earlier runtime
expression executes; that expression replaces the pending answer with 7. The
same ordering holds for floating and pointer blocks. The original timing/answer
format is checked through public CmdLinePmt; the retained native physical console
continues using its established compact numeric format.

`build/i386-answer-prompt-native-baseline-v4` fails the nested-directory case on
the prior compiler89 image. Its full raw capture also preserves the bare blocks'
missing pending-answer updates. Five new cases fail semantically on this image:
the directory macro, three bare typed blocks and counter assignment. Initial incorrect scalar/lookahead expectations,
a deliberate-rejection harness failure and a native filesystem-check variable
collision are retained as failed attempts, with terminal input audits and source
snapshots where available. They do not count as passing runs.

The interactive stream test derives its corrected no-scalar nested-include
expectation from this original capture. It also checks all three bare block
answer categories and runtime-after-lookahead cases. Its prior directory/value,
generated code, side effects and persisted-fixture assertions remain.

Stream cancellation, failure/ownership, literal-pointer retention, AOT and normal
public compiler delivery still need qualification. No additional whole workflow
or C1–C5 release gate is closed by this component test.


Both bootstrap generations and the full 1,763-source native build pass;
independent source/build-input audits match. The full source26 regression passes
with all 1,039 input pins independently verified. Directory-v1, Carry-v1 and
ClassMeta-v1 regressions pass on the stream-answer candidate. Fresh 8 MiB normal
and 16 MiB diagnostic boots match all 307,200 welcome pixels, and both diagnostic
program/code-ownership/file-break phases complete. Evidence is under
`build/i386-stream-answer-*`, including `memory-audit.json` in the cross-build.


`build/i386-stream-answer-console34-v1` passes the complete existing 34-command
normal console regression at 8 MiB KVM, 486 without FPU, with live WinMgr and exact
VGA checks. It covers ordinary final answers, typed formatting, included values,
void suppression, declaration-only preservation, syntax recovery, nested document
execution and integer/F64/pointer initializers. Its original-reference reader
accepts the historical nine-case capture and the expanded sixteen/seventeen-case
captures. All terminal input hashes are independently checked.


`build/i386-stream-answer-interactive-v3` passes all 23 commands on TCG 486
without FPU at 64 MiB. Exact welcome/typing/result rasters, all directory values,
restored context, generated functions and persisted fixture bytes pass. The
normal source image and runner pins remain unchanged. WinMgr stays live: the
preceding v2 harness suspended it before the pause command's final prompt was
drawn, freezing a stale frame before any stream command. The v1 attempt retains
the obsolete no-answer expectation for the counter assignment; a new original
capture proves that assignment must present 1 and execute exactly once. No
runtime change was needed for either harness correction.


Compiler91 follows up the literal-pointer gap: compile-time outputs carrying
CCF_HAS_MISC_DATA now use the same retained-pool ownership as ordinary execution.
The unchanged seventeen-case pending-answer regression passes. A code-heap reuse
probe reproduces freed literal corruption on compiler90 and passes on the
candidate; see [literal evidence](i386-stream-literal.md). Broader ownership,
failure/cancellation and release gates remain open.
