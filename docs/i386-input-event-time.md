# Public keyboard state and last input time

The complete original CKbdStateGlbls declaration and KbdMsEvtTime body are shared
through KeyboardStateTypes.HH and KbdMsEventTimeCore.HC. They match the preceding
original definitions byte-for-byte apart from the type's trailing blank lines.
The original wrappers include them in place. Console ABI 206 publishes the
function and task-independent keyboard state in 576 bindings, with the state
correctly marked as data.

The original timing decision is preserved: compare the hard mouse timestamp
with the latest raw keyboard timestamp; otherwise return the latest decoded-key
timestamp. This can differ from taking the maximum of mouse and decoded-key
timestamps. The raw input observer runs for both keyboard and mouse bytes,
including debugger polling, with interrupts masked. It records the existing
native PIT timestamp source; its frequency is the published 1,193,182 units per
second. The observer allocates nothing and does not change input routing.

The scheduled keyboard decoder updates scan_code, last_down_scan_code, cnt,
new_key_timestamp and both down bitmaps before posting the public event. Both
make and break events count, as in the original handler. Logical mouse updates
now modify the actual shared scan-code mouse flags. The original private FIFO
pointer fields remain in the public layout; native device buffering continues
to use its existing controller queue and persistent decoder rather than those
private implementation fields.

Two generations of the original rebuild pass
(`build/input-event-time-rebuild-v1.log`). The original timing contract passes
mask 31 for zero, mouse-newer, equal raw timestamps, keyboard-newer and a mouse
value between raw and decoded-key values
(`build/i386-input-event-time-reference-v2/result.json`). That fixture masks IRQs
and restores the actual original globals. These are decision cases, not physical
input events.

The native contract injects actual QEMU PS/2 make/break events and mouse motion.
It checks public counts, scan codes, released bitmaps, raw/decoded-key timestamp
relationships, and mouse activity advancing KbdMsEvtTime without changing either
keyboard timestamp. The real window manager remains active. After the mouse-only observation is recorded, a real follow-up key lets the
fixture finish; the pointer display may be replaced by a keyboard refresh.
Every framebuffer pixel after each interaction and a subsequent arithmetic
command match. The contract passes with unchanged run inputs in
`build/i386-input-event-time-native-v4/result.json`. See
`tools/test-i386-input-event-time.py`; this does not qualify pointer rendering.

The full-content image passes the 386 instruction audit and independently
matches all 1,254 packaged candidate source/documentation files
(`build/i386-input-event-time-cross-v1/source-audit.json`). The unchanged MakeAC
source now compiles past DocTermNew, KbdMsEvtTime and kbd.scan_code and rejects at
missing sys_run_level, ACTask.HC line 265
(`build/i386-input-event-time-autocomplete-v1/result.json`, input pins unchanged).
No autocomplete task is explicitly activated. Autocomplete initialization,
suggestions, complete keyboard mappings, typematic, input-loss state recovery,
device failures, full minimal regressions and release qualification remain open.

The earlier attempts remain failures: v1 omitted the welcome document's colors;
v2 did not drain the submitted command's key release before sampling mouse-only
state; v3 expected a persistent mouse pointer although the actual frame had
returned to a keyboard cursor. The final fixture synchronizes those input stages
and checks every pixel after the follow-up key. It does not relax pixel matching.

The 8 MiB normal-startup smoke passes in 41.67 seconds with live WinMgr/welcome,
public keyboard-state and timing access, and exact framebuffer checkpoints
(`build/i386-input-event-time-minimal8-v1/result.json`). This is not the complete
minimal-profile suite. The host checker had only trailing whitespace removed
after the passing hardware run; guest sources and fixture bytes are unchanged.
