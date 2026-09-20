# Keyboard break requests during console submissions

ConsoleRuntime now retains an IRQ-side keyboard observer with decoder state
separate from the buffered reader. It sees every controller byte, including
modifier releases, and recognizes an unextended C make while either Ctrl and
either Alt are held. The existing decoder handles prefixes, repeat makes,
auxiliary bytes and invalid input; invalid keyboard packets reset modifier state.

While an executable console submission is active, Ctrl-Alt-C requests a break
on its task. The IRQ callback may unlink/wake a registered wait, but never
allocates, switches tasks or throws. Compiler checkpoints and their protected
unwind still deliver the exception on the task stack. A triggering C make is
consumed so it does not become a second line-cancel command after recovery.
Releases remain in the raw stream so buffered key state cannot remain stuck.
Without an active submission, the existing console input path handles the keys.
Mandatory public-header loading is not an interactive break target.

The active task pointer is installed and cleared under IRQ masking and never
outlives the synchronous ConsoleSource call. After normal compiler return the
console clears the target and polls within its own try/catch, covering a request
arriving after the compiler's final checkpoint. The catch also clears the pointer
before reporting recovery. The retained module and decoder state live for the
kernel lifetime. Controller setup and IRQ unmasking occur after console loading
and initialization, so the kernel can call the validated callback directly.

ConsoleRuntime advances to version 12. Its six-entry service table is 32 bytes;
the configuration remains 28 bytes. The console imports the kernel's throw for its task-context poll; no new public
Break/Yield symbol is exported.
CompilerRuntime remains version 45. Version 11 consoles are rejected before
callbacks run.

Component tests exercise both left/right Ctrl and Alt combinations, repeat makes,
release, auxiliary/no-data input, corrupt packets, missing modifiers, wrong keys
and extended-key rejection. The QEMU console test defines a HolyC function that
emits a debug marker and waits for TASKf_PENDING_BREAK. Only after observing the
execution marker does the host send actual Ctrl-Alt-C key events. Immediate and
lock-delayed requests must recover with exact VGA output and allow subsequent
commands; the host never writes the pending flag or guest memory.

The test program cooperates by observing the request and returning. This proves
IRQ-side request production during running HolyC, not interruption of arbitrary
non-returning code. The subsequent [generated loop checkpoints](i386-loop-break-checkpoints.md)
add delivery for native while/goto/do-while loops, including a user catch handler.
Focused multi-task routing, original message/job/popup semantics and original
DolDoc integration remain required for the editing-session goal.

Validation passed both x64 rebuild generations, the native input suite and the
full kernel suite: 143 console commands, 206 input lines, two real keyboard-break
cases, exact VGA, startup recovery and 17 rejection cases. The refreshed preview
contains the request path. See [port progress](port-progress.md) for sizes and
timings.
