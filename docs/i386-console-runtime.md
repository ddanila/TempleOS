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

Strict 386SX/DX, physical hardware, complete language/document workflows and native
compiler/kernel self-hosting remain required acceptance gates.
