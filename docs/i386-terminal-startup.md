# Original terminal startup contract

The original-system control in
`build/i386-c2-terminal-startup-exact-reference` passes with unchanged fixture
and tool hashes. It runs the pinned original system used by the TimeClock
reference, calls the original `DocTermNew`, types the complete original
`::/Doc/Start.DD`, and clears the resulting document.

The fixture checks that the terminal put/display document is shared, its entry
limit is 4096, its border and menu exist, and raw output is off. Three exported
buffers establish the document sequence:

| Stage | Exact saved bytes |
| --- | --- |
| Fresh terminal | Empty (zero bytes) |
| After original `Type` | Entire original `Doc/Start.DD`, then newline and byte 0x05 |
| After `DocClear` | `$WW+H,1$`, then byte 0x05 |

The host compares the entire welcome buffer to the pinned source, including all
links and formatting. It does not normalize DolDoc commands. The initial run
in `build/i386-c2-terminal-startup-reference` failed a fixture expectation that
an empty terminal saves a 0x05 terminator; the actual empty document saves zero
bytes. Its observations are retained, and the corrected fresh run passes.

```sh
python3 tools/test-i386-terminal-startup-reference.py --out OUTPUT
```

This independently confirms the startup cause of the strict native TimeClock
report mismatch described in [the native application evidence](i386-timeclock-native.md).
It is an original reference contract, not native startup qualification.

Native integration still needs the complete `DocTermNew` path, including its
right-click callback, border, menu and scroll initialization, followed by the
original welcome insertion. `NativeTerminalTranscriptStart` currently writes a
minimal heading. The full original `DocType`/`Type` path also depends on `DocDump`
for raw output and `DocGR` for graphics files. The graphics branch calls `GRRead`,
`DCLoad`, `DC2Sprite` and `DocSprite`; importing only the text branch would leave
the public function incomplete. Desktop task orchestration in `HomeSys.HC`
remains separate outstanding work. Preserve the minimal 8 MiB boot contract
while implementing the full desktop profile. No inventory entry or milestone
is qualified by this reference test.
