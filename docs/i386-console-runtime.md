# Retained native HolyC console

`ConsoleRuntime.t32m` owns the VGA text console, original 8×8 font, keyboard line
editing, command submission, diagnostics and scalar answer rendering. Its ABI 1
service record is 20 bytes: version/size followed by initialization, display and
keyboard-task entries. The kernel validates those entry addresses inside the
loaded image before publishing the record. The image stays resident for the
kernel lifetime; it cannot be unloaded while its task, callbacks or font are used.

A separate borrowed configuration supplies the heap, compiler/file/include
services, internal types, keyboard reader and resident read callback. Kernel
storage backs this configuration for the entire module lifetime. Initialization
is one-shot. Display initialization allocates the same 153600-byte planar buffer
as before, initializes the original palette/font and reports success explicitly.
The boot startup module still calls the resident `KernelDisplay` wrapper and is
then reclaimed; it does not own the retained console.

The module imports only `KernelLog`, `KernelStop`, `I386HeapAlloc`, `SysTry` and
`SysUntry`. It compiles the existing VGA/text implementation and I/O intrinsics
without introducing a host runtime or a newer CPU requirement. Device setup,
keyboard interrupts and cooperative scheduling stay in the kernel. The console task starts after boot/worker heap-accounting diagnostics finish.
It has a 64 KiB stack and borrows the shared kernel heap for symbols, compilation
and exception records. Submitted input always takes its heap from the current
task symbol scope; the configuration heap owns the display buffer. A single task
owns keyboard consumption and VGA writes after boot display initialization.

## Source startup

Before the first prompt, the console task compiles and executes an include of
`/Kernel/I386/StartOS.HC` from RedSea through the same native input service used by
keyboard commands. The packaged default supplies `NULL`, `TRUE` and `FALSE`.
Definitions and executable commands can be added to this source; successful
functions, globals and macros remain in the console task's scope. The compiler
reads the disk file at boot, so changing source does not require recompiling the
console module. Repack the image to change this file until native editing and
file-writing workflows are integrated.

The source runs once, after worker heap-accounting probes and task creation, with
the console's file context, symbol heap and recoverable input boundary. Its source
buffers belong to the include/control lifecycle. Results and diagnostics use the
usual console callbacks. A missing file or failed compilation still reaches the
prompt after cleanup. Publication and side effects follow the normal input rules:
a failed source does not publish its private classes/functions/globals, but earlier
executed side effects are not rolled back. Preprocessor defines enter the task
scope immediately and can remain after a later failure. Language exceptions recover through the console;
CPU faults remain fatal and an indefinitely running startup command has no
interactive interruption mechanism yet.

The early `Startup.t32m` still performs display initialization and is reclaimed.
It remains cross-compiled. The `DONE native kernel startup` diagnostic now comes
from the console after source execution and prompt presentation, rather than from
the root immediately after spawning the task. This is source-driven console
startup, not completion of the original full StartOS/DolDoc bootstrap.

## Submitted commands

Enter submits the current line through CompilerRuntime's input service. Results
are rendered synchronously; successful definitions persist in the console task's
symbol scope. Later syntax errors report a diagnostic and return to the prompt
without deleting prior definitions. Other exceptions unwind the private compiler
control and are caught by the console. CPU faults still use the fatal kernel
handler pending debugger integration. Compilation/execution is not transactional:
earlier user-code side effects remain if a later command fails.

The console preserves backspace, wrapping, tabs, scrolling and Ctrl+C cancellation
of the currently edited line. Each line is limited to 255 bytes. Multiline input,
interactive interruption of executing code, command history, full public answer
APIs and DolDoc editing remain open. This is an initial native programming console,
not completion of the full TempleOS environment. `Print`, native assembler/try
providers, generators and other language/runtime integration remain separate work.

Signed and unsigned integers render in decimal, pointers as hexadecimal addresses.
Pointer classification uses the value class because `RT_PTR` and `RT_I64` share
a raw-type code. Floating-point answers use an integer-only exact decimal
expansion followed by nearest-even rounding to 17 significant digits. This handles
subnormals, extrema, signed zero, infinities and NaNs without a 387. Fixed notation
is used for decimal exponents from -4 through 16, scientific notation otherwise.
This scalar renderer is not yet the full public formatting implementation; its
worst-case latency on actual vintage hardware remains to be measured.

## VGA update ownership and bounds

The private `CI386Text` record is now 32 bytes, including `dirty_first` and
`dirty_last` text-row bounds with an exclusive end. Its canonical clean state is
`60,0`. Glyph writes merge their row into the pending interval; initialization
and scrolling invalidate all 60 rows. Cursor-only changes leave pixels clean.
Consumers of the record must rebuild; ConsoleRuntime's external ABI remains 1/20.

`I386TextPresent` returns the number of uploaded text rows, zero when clean, or
-1 on invalid state. It clears the pending interval only after success. The bridge
calls `I386VgaRows`, whose bounds are scanlines, with eight scanlines per text row.
The VGA function requires the complete 153600-byte logical buffer and validates
address wrap and the range before accessing hardware. A valid empty range does
no work. `I386VgaPresent` retains the full-screen entry point.

One ordinary edited row now uploads 2560 bytes instead of 153600. Initialization
and scrolling still upload the full screen. The console owns the text record,
framebuffer and VGA registers; IRQ handlers do not access VGA and presentation
does not mask interrupts for the copy. Direct framebuffer writers must invalidate
the affected rows themselves. Debug-port `VGA ROWS NN` records expose requested
upload spans for tests without adding display text. These counts measure payload,
not bus timing; full-scroll cost and vintage-machine input latency remain open.

## Verification

`python3 tools/test-rebuild.py` and `python3 tools/build-i386-kernel.py --test`
rebuild and exercise the image. The verifier audits executable instructions and
module imports/entry addresses, checks retained image accounting, and corrupts
console target/import/version records to prove rejection before startup use.

The keyboard harness sends actual emulated key events and compares every VGA
pixel to an independent renderer using the original font. In addition to line
editing it types arithmetic, persistent globals/functions/static state, malformed
input followed by successful calls, full-width integers, pointer values and F64
boundary values. No test injects precompiled answers into the console.

Additional boots change only the startup source bytes or its directory name in
copies of the same disk. They verify a native startup call and persistent
function/global/macro state, syntax-error cleanup without publishing private
definitions while preserving an earlier preprocessor define, and recovery from a
missing file. Each case types new commands and
checks the resulting pixels; module bytes remain unchanged.

Strict 386SX/DX, physical hardware, complete language/document workflows and native
compiler/kernel self-hosting remain required acceptance gates.
