# GetStr compatibility

GetStr is the next missing public API encountered while compiling unchanged
TimeClock source (TimeClk.HC line 127). This work contributes to C1 reference
coverage and C4 API compatibility; it does not qualify TimeClock or C2–C5.

## Original-system observations

`tools/test-i386-getstr-reference.py` restores all 686 original paths using the
same archived/repaired revisions as the TimeClock reference capture. Original
compiler and kernel binaries are restored too. The disposable guest feeds
`In` text into `GetStr`, exports each returned allocation including its NUL,
and compares the captured bytes with explicit host expectations.

| Input | Default / flags | Returned bytes before NUL |
| --- | --- | --- |
| `alpha` then Enter | none | `alpha` |
| Enter | none | empty |
| Enter | `fallback` | `fallback` |
| `alpha` Enter `beta` Enter Esc | `GSF_WITH_NEW_LINE` | `alpha\nbeta\n` |
| `discard` then Shift-Esc | none | empty |
| `discard` then Shift-Esc | `fallback` | `fallback` |

All six pass in `build/i386-c1-getstr-reference/result.json`. The trailing
newline and cancellation/default behavior are observed original behavior,
not implementation conveniences. The shared reference-restoration helper was
also rechecked with the existing TimeClock storage/report oracle:
`build/i386-c1-timeclock-reference-helper/result.json` passes.

```sh
python3 tools/test-i386-getstr-reference.py --out build/getstr-reference
python3 tools/test-i386-getstr.py IMAGE --out build/getstr-native
```

Both runners require fresh output directories. Native testing uses a writable
copy, records unchanged input hashes and requires public-interface results and
exact VGA answers on the no-FPU 486 QEMU profile at 64 MiB.

The native baseline `build/i386-c1-getstr-red/result.json` fails at the first
`GetStr` call with `Invalid lval` / `INPUT REJECT`, after the declaration
command succeeds. Input hashes remain unchanged. This is the expected missing
binding failure, not evidence that the later five cases execute natively.

## Architectural work

The original `Kernel/SerialDev/Message.HC` wrapper prints the optional prompt,
calls `fp_getstr2`, and replaces an empty result with a separately allocated
default or empty string. `Adam/DolDoc/DocGet.HC` implements that service against
the task's output document: prompt markers delimit input, `DocGetKey` drives
editing, and `DocScanLine` extracts document entries. Enter submits single-line
input; multiline input ends on Esc. Shift-Esc cancels or exits the task when
`GSF_SHIFT_ESC_EXIT` is set. Ctrl-Shift-Enter inserts a line without submitting.
Esc can execute the current document entry before ending multiline input.

The port already has a DolDoc editing model and public task key queues, but
`NativePutS` writes normal console output directly to `console_text`, bypassing
`Fs->put_doc`. `NativeReadKey` consumes task messages; the full-screen `DocEd`
loop is a separate client. Therefore merely exposing a new string-buffer loop,
or invoking the full-screen editor for each prompt, would leave the original
inline document/input semantics missing.

Next work must connect output/input to the task's canonical document, share
line extraction and key processing where possible, and preserve terminal
history and command entry. Add tests for real keyboard editing, prompt
formatting, Ctrl-Shift-Enter, Esc entry execution, filter exit, cancellation,
exception cleanup and `GSF_SHIFT_ESC_EXIT`; the six scripted cases alone do not
qualify those behaviors. Recheck existing terminal, input-filter and document
workflows after integration. No native GetStr implementation is claimed here.
