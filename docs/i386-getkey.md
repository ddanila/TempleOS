# Native GetKey wait, cursor and polling

`Kernel/KeyGetCore.HC` shares the original GetKey message loop, echo, scan-code
return and task-flag transitions. Platform hooks replace its timestamp source,
raw cursor output and interrupt-masked keyboard polling. The original kernel
keeps its own TSC and polling implementation; native code uses PIT/jiffy timing,
managed yielding and the existing VGA staging surface. Console interface 76
exposes the native GetKey binding.

## Platform adapters

The native cursor clock combines timer ticks and latched channel-zero PIT
counts, with per-call state. When interrupts are masked, polling accumulates
counter wraps without requiring RDTSC or an FPU. Cursor output bypasses document
recording so its block/backspace does not become input text. This is not a
qualification of absolute clock precision or every raw-text edge case.

KernelInputPoll reads one controller byte and uses the same keyboard/auxiliary
routing as IRQ delivery. The scheduled keyboard worker and debugger polling
share NativeKeyboardPump and its decoder state. The debugger adapter masks
interrupts while draining/routing controller data, decoding and posting normal
key messages, then restores the caller's flags. Ordinary delivery retains the
managed message queue and worker.

The first raw-cursor test exposed a scheduler difference: native Yield parks a
task with TASKf_AWAITING_MSG, so cursor redraw stopped until a new message. The
native wait hook keeps an active raw-cursor waiter runnable while yielding;
ordinary GetKey waits retain message parking. The common GetKey loop still sets
idle/awaiting state and clears idle after waiting.

## Oracles and remaining work

The 28-field input oracle covers empty/reset/filter/NULL/zero-character cases,
GetKey echo and scan codes, descriptor handling, and delayed delivery with a
producer waiting for idle/awaiting flags. Its consuming hook now uses priority
10 in both original and native fixtures. The earlier I64_MAX hook ran after the
document sink and legitimately echoed a glyph, which the native VGA fixture
had not accounted for. This correction isolates callback behavior; it does not
qualify full default document echo.

`tools/test-i386-getkey-physical.py` supplies actual QEMU keys after checking a
raw cursor's visible and erased framebuffer states. It exercises scheduled
GetKey and debugger-mode GetKey with IF masked, checks returned character/scan
code, restores mode and flags, and confirms the console still executes code.
Default document output, GetChar, DocGetKey/GetStr, entry replay, input filters,
forced exit/unwind, precise blink timing and complete debugger combinations
remain separate compatibility work. No C1–C5 milestone is closed by this API.

## Verification checkpoint

The pinned original with the early consuming hook passes all 28 fields in
`build/i386-c1-getkey-early-hook-reference/result.json`. The same oracle on the
rebuilt x64 control passes in `build/i386-c4-getkey-control-final/result.json`.
The native full message/echo/delayed-producer suite passes in
`build/i386-c4-getkey-queue-final/result.json`, including zero-character return,
scan-code preservation and normal wait-state observation. This advances the
previous missing-GetKey red gate; its full collection now executes.

Physical scheduled and interrupt-masked debugger cases pass in
`build/i386-c4-getkey-physical-rows/result.json`. Each checks complete visible
and erased cursor frames and receives a real QEMU key. The masked case also
requires IF to remain clear on return from GetKey until the fixture restores it.
The harness now supports explicit interaction return rows; existing default
return-frame behavior is preserved. The raw fixture accounts for blank-line
clearing leaving the text cursor at the bottom rather than resetting it home.

Original two-generation bootstrap and 386 cross-build audits pass. The final
packaged image, including the updated harness provenance, is
`build/i386-c4-getkey-final-cross`. Earlier cursor/fixture failures remain
recorded in `build/i386-c4-getkey-physical` and `-physical-final`; they are not
passing acceptance evidence. The first queue fixture's late echo hook caused
legitimate default-sink output; both paired fixtures now explicitly isolate the
consuming callback at priority 10.

The final packaged candidate passes the thirteen-command transcript suite in
`build/i386-c4-getkey-transcript/result.json` and the existing two-terminal
regression in `build/i386-c4-getkey-terminals/result.json`. The nine-command
8 MiB startup gate passes in 45.0204 seconds with zero build-provider loads in
`build/i386-c4-getkey-startup-final/result.json`. These focused checks do not
close background concurrency, lifecycle/unwind or full native-generation gates.
