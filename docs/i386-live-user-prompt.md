# Live User prompt baseline

The direct `CmdLinePmt` tests do not establish that a normal terminal calls it.
`tools/test-i386-live-user-prompt.py` observes an actual `User` child, first
idle, then after physical keyboard input `6*7;` and `1.5+2.25;`. It captures
answer/type/pending/prompt state and the complete serialized document at each
boundary. It installs no replacement input or prompt loop.

The pinned original passes; native executes both commands but fails the live
prompt document contract. This is test-first evidence for an open C2 requirement,
not a newly qualified compatibility item.

| Observation | Original | Native |
| --- | --- | --- |
| Initial prompt | Independent root directory followed by `>` | `> ` without directory |
| Integer | Elapsed time and `ans=0x0000002A=42`, then directory prompt | `42`, then `> ` |
| Float | Elapsed time and `ansf=      3.7500000`, then directory prompt | `3.75`, then `> ` |
| Integer state | Answer42, type10, pending0, prompt1 | Same |
| Float state | Float answer, type14, pending0, prompt1 | Same, with the known decimal conversion difference |

The frozen oracle, `tests/i386/live-user-prompt-reference.json`, records fixture
hash and original/repair provenance. It compares complete document bytes,
including prompt/color/word-wrap/cursor serialization, after normalizing only
six-decimal elapsed fields and the independently captured drive-root spelling
(original T:/, native C:/). Successive captures must contain one/two/three elapsed
fields. No style, whitespace or document content is masked.

Raw float bits remain recorded: original0x400e000000000001 and
native0x400e000000000000. The explicit two-value allowance already used by
`test-i386-answer-prompt-reference.py` accounts for the original decimal/x87
one-ULP behavior; observations are not rounded or overwritten. This is not a
new floating-point compatibility qualification.

Initialization uses self-contained queued source in the child, a trailing newline
and an explicit pointer handshake. It does not assume that `User` inherits the
launching user's symbols. Both measured commands use physical QMP key events;
an independent audit checks their exact event sequences. Capture buffers and
the parent namespace stay live until host capture. Resource reclamation and
full raster compatibility are outside this fixture's scope.

Reproduce with fresh directories:

```sh
python3 tools/test-i386-live-user-prompt.py --out build/live-prompt-reference-NEW
python3 tools/test-i386-live-user-prompt.py --disk build/i386-emitter-known-cross-v1/kernel.img --out build/live-prompt-native-NEW
```

The versioned `build/live-user-prompt-reference-v1` passes the frozen oracle with
unchanged inputs. Receipt SHA256:
a9fb12264ccd99a1b2c21db319d1fdee56afefb68f878919c50369e282f52d55.
`build/live-user-prompt-native-v1` at64MiB KVM486,-fpu fails only the directory,
deferred-answer, elapsed-field and complete-document checks; numeric and prompt
state checks pass. Receipt SHA256:
eff07167d2e75f13b7753048f9fcc9b3ab839f42145f7b3641ab3594ace70c88.
`build/live-user-prompt-comparison-v1/result.json` independently checks inputs,
raw exports, states, exact key-event suffixes and outcomes. Its status is
observed-gap, with native_pass FALSE.

Prototype v1-v3 artifacts and invalid-fixture records remain under `build/`:
missing initializer newline, child namespace assumption, and an exact-only float
guard omitting the established ULP allowance. None is product failure evidence.
Corrected prototype v4 first establishes the gap; the versioned runs above
independently reproduce it.

The production path still uses `NativeTerminalInput`, `NativeConsolePrompt` and
reduced answer presentation through `NativeUserTaskCont`. Original
UserTaskCont/CmdLinePmt/GetStr/ExeCmdLine integration, editing, interruption,
recovery, persistence and broader desktop workflows remain open. Inventory
stays2/686; C1-C5 are not complete.
