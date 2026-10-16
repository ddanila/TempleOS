# Original diagnostic printing

Current status: pinned and rebuilt originals pass all eight shared cases.
Native cases 0-6 pass; pending raw-dollar case 7 still fails because the raw
key-device handlers are absent. The full diagnostic gate remains failing.
Normal 8 MiB startup passes on the validator-sharing image in 58.282055 seconds,
with nine commands, exact VGA restoration and no Build-provider load. This is
partial API integration, not full diagnostic/raw-output or desktop acceptance.

Drive changes and media initialization use PrintErr. The native console lacked
that public service and GetOutOfDollar, which closes an unfinished dollar
command before diagnostic text. This work shares the complete original
GetOutOfDollar, PrintErr and PrintWarn bodies, rather than replacing diagnostic
output with plain text. Kernel/DiagnosticText.HH also shares the original error
and warning format strings. Console version 118 exports all three services. The original Print body is
also shared for the compiler-generated output calls inside these routines;
existing public NativePrint routing is unchanged.

The callback used by GetOutOfDollar points to the real DocPut service after
ConsoleInit. It is assigned at runtime because native compilation rejects a
function address in a global initializer. The first cross-build rejection is
preserved in build/i386-c4-diagnostic-print-cross. A subsequent rejection in
build/i386-c4-diagnostic-print-callback-cross identified missing Print/PutChars
headers before the original output shorthand. Their declarations and shared
Print implementation now precede the new routines. No original routine branch
was removed to work around that compiler restriction.

The shared fixture tests/guest/i386-diagnostic-print-reference/Contract.HC
covers eight cases:

- Document output with no pending dollar command and with a pending FG command.
- PrintErr and PrintWarn, each with and without a pending dollar command.
- Raw output with no pending dollar command and with a pending FG command.

The document cases inspect exact message suffixes, four caller-prefix fields,
the original foreground/blink command sequence, restored formatting, closed
dollar state, unchanged document roles and exact heap recovery. Caller names
and addresses depend on build/layout and are not compared byte-for-byte. The
raw cases check closed raw-dollar state, retained raw mode, unchanged document
entry identity and roles, and heap recovery. They restore the saved raw flags,
column and mode. These contracts do not qualify complete raw screen rendering,
exceptional allocation failure or all diagnostic callers.

build/i386-c4-diagnostic-print-raw-reference passes all eight masks of 31 on the
pinned original. The eight-case rebuilt-original control passes in
build/i386-c4-diagnostic-print-raw-current-reference. The stronger pending-raw
state assertion passes on pinned original in
build/i386-c4-diagnostic-print-state-reference.
The native preflight in build/i386-c4-diagnostic-print-red rejects the missing
GetOutOfDollar binding with unchanged inputs. It does not execute the fixture.
build/i386-diagnostic-print-extraction.json verifies byte-exact reconstruction
of the original source files from the extracted routine bodies.

Exploratory failures remain visible: the first fixture used unsupported ternary
syntax; the next incorrectly treated entry attr as rendered foreground/blink;
and a strengthened caller check incorrectly expected links from lowercase %p.
Original source and observations establish that %p emits plain caller text,
while uppercase %P emits links. The final contract checks the four caller fields
and formatting commands actually produced by the original routines.

The first built native image passes diagnostic cases 0 through 6, then rejects
case 7 in build/i386-c4-diagnostic-print-native with unchanged inputs. This is
an actual missing raw-output route: NativeKeyDevStart installs the input filter
and document handlers, but not the original KDRawPutKey/KDRawPutS handlers.
The raw test remains failing; document success is not full acceptance.

The same image fails the minimal 8 MiB startup regression at NativeGraphicsStart
(startup command 6) in build/i386-c4-diagnostic-print-startup. Adding the services
grew ConsoleRuntime's retained image by 2,536 bytes and exhausted the parser's
backing allocation. The candidate correction shares export-value setup across
all 299 bindings instead of repeating stack-array addressing and conversion in
ConsoleInit. build/i386-diagnostic-print-export-map.json records identical
ordered bindings before and after this transformation. Names, symbol kinds and
registration order are unchanged. Its memory benefit and runtime qualification
must be measured before calling this regression resolved.

The first shared-helper build, build/i386-c4-diagnostic-print-export-cross,
reduces the retained Console image from 2,349,400 to 2,347,808 bytes and
ConsoleInit from 43,640 to 42,184 bytes. This is a measured 1,592-byte retained
saving; it is not evidence by itself that the 8 MiB gate passes. The full native
diagnostic test, minimal startup and broader public task-kill regression are
being run against that exact image.

The first helper is insufficient: build/i386-c4-diagnostic-print-export-startup
still fails at NativeGraphicsStart. Its native diagnostic run again passes
cases 0-6 and fails case 7 with mask 30 and pending=0, confirming that Raw(TRUE)
never sends the opening dollar command through a raw handler. The revised
initialization helper advances a cursor through the same ordered table, saving
one index argument at every call. Its cursor resets before binding zero; the
normal name/kind/registration loop remains unchanged. Ordered mapping identity
is recorded in build/i386-diagnostic-print-cursor-export-map.json.

The cursor build measures 2,344,840 retained Console bytes and 39,232 bytes for
ConsoleInit: a 4,560-byte retained saving against the initial diagnostic build.
The cross build in build/i386-c4-diagnostic-print-cursor-cross passes its 386
instruction audit, with all 1495 source and 24 build-input hashes matching.
The current original-system control passes all eight cases in
build/i386-c4-diagnostic-print-cursor-reference. The earlier two-argument helper
also passes the 69-command/nine-case public kill regression at 64 MiB with its
source disk unchanged in build/i386-c4-diagnostic-print-export-kill.

The cursor image passes all nine public kill cases/69 commands at 64 MiB with
an unchanged source disk (build/i386-c4-diagnostic-print-cursor-kill), but its
minimal startup still fails, now at command 4: a 537-byte parser payload cannot
fit the largest free block (360 bytes), despite remaining fragmented space.
Its native diagnostics still pass cases 0-6 and fail case 7. These results
remain failures; reducing retained code alone is not a minimal-profile pass.

The next candidate replaces the repeated data-kind comparisons with a 40-byte
bitmap. build/i386-diagnostic-print-export-kinds.json verifies exactly the same
12 data-export indices among the 299 bindings. No allocator policy, memory
limit, public service, oracle or startup workload is changed.

The bitmap candidate still fails the minimal gate. Independent stopped heap
snapshots, build/i386-c4-diagnostic-memory-before and ...-after, explain the
remaining pressure: the last passing image uses 6,601,616 of 6,629,888 bytes,
with 9,611 allocations and a 15,328-byte largest free block. The bitmap candidate
uses 6,602,456 bytes, with 9,651 allocations and a 14,304-byte largest free block.
The additional declarations require forty retained allocations; code savings
had not yet offset their full cost. These snapshots are not timing gates.

A larger duplicate was identified: CompilerRuntime retained 23,696 bytes of
module-validator code already present in the boot kernel. ModuleCheckBridge.HC
now delegates to that complete, unchanged kernel validator. Two local wrappers
retain the provider-local export addresses required by KernelResidentPublish;
no publication range check is relaxed. The kernel supplies two explicitly named
bindings, and CompilerRuntime version 71 records the new binding contract.
The canonical validator still passes all 176 malformed/valid target cases in
build/i386-module-check. The new retained binding fixture separately checks
whole-module and callback-based validation, malformed input, restored bytes and
caller heap recovery through the installed provider interface.

The final cross image is build/i386-c4-diagnostic-print-validator-cross:
579,184 kernel bytes, all 1496 source and 24 build-input hashes matching.
CompilerRuntime shrinks from 1,764,592 to 1,741,440 retained bytes; the kernel
adds 240 bytes for the two bindings. Bootstrap passes both generations. The
normal minimal gate passes in build/i386-c4-diagnostic-print-validator-startup
(58.282055 seconds, nine commands, exact VGA, no Build provider).
The current original control passes eight masks in
build/i386-c4-diagnostic-print-validator-reference. Native cases 0-6 pass and
case 7 still fails with unchanged inputs in
build/i386-c4-diagnostic-print-validator-native.

The first installed-validator fixture declared an unnecessary import and was
rejected before execution (build/i386-c4-validator-binding-native). These
already-bound services use extern declarations in the corrected fixture.

Complete the raw path from the original Kernel/Display.HC RawPutChar and
Kernel/KeyDev.HC handlers. A dollar-state-only shim would leave the original
character, tab/backspace/newline, scrolling, cached font rendering and hardware
behavior unported. Add independent raw cache/framebuffer observations before
claiming that path qualified.

The corrected installed-provider fixture passes all nine cases/eleven commands
at 64 MiB in build/i386-c4-validator-binding-extern-native, with unchanged
inputs and a byte-identical delivered fixture. Both whole-buffer and streamed
callback validation reject malformed inputs, accept the restored module and
recover the caller's heap exactly. The source disk remains unchanged.

The final image also passes the broader public task-kill regression: all nine
cases/69 commands at 64 MiB, with an unchanged source disk, in
build/i386-c4-diagnostic-print-validator-kill. The detached selected-module C5
build remains live on its older 9d64ad4b snapshot; it does not qualify this
latest source or two full native generations.
