# Native public task and CPU headers

The console loads `/Kernel/I386/PublicKernel.HH` through the native compiler
before `/Kernel/I386/StartOS.HC`. The header includes the shared complete `CTask`,
`CCPU`, hash, job-control and window-scroll definitions, and declares typed `Fs`
and `Gs` intrinsics. It uses the same records as the resident scheduler; it does
not introduce shortened public substitutes.

Header loading is a separate compiler input. User startup may fail or be absent
without removing these definitions. A failed system-header load stops startup
with its diagnostic visible, because continuing without the public contract
would conceal a broken installation.

## Header macro transactions

`I386_INPUT_ATOMIC_DEFINES` is an opt-in flag on `CI386CommandInput.flags`. It may
be combined with `CCF_JUST_LOAD`, as the console does for its public headers.
The frontend inserts a private macro table between its private declarations and
the task's existing symbols. Includes and subsequent tokens see staged macros;
other compiler inputs continue to see the task's published scope.

Publication validates declarations and macros before moving either into the task
scope under IRQ exclusion. Repeated macro definitions retain their lookup order.
A rejected definition, syntax error or exception leaves existing guards and types
intact. Macro graphs and their table belong to the compiler control, so normal
unwind and task cleanup reclaim unpublished definitions through the same path.

This mode does not roll back executed code or external side effects. Ordinary
input retains immediate macro publication, including macros defined before a
later syntax error. Header macros cannot collide with declarations in the same
input or non-macro symbols already in the destination scope.

## Native assertions and lexer ownership

The lexer service record now has an optional parser-directive callback. A native
frontend supplies its own callback while forwarding the existing file-include
service. Raw lexer clients leave the callback null and continue to reject
unsupported parser-dependent directives.

`#assert` evaluates its expression through the native compiler and runtime. A
false result issues a warning, matching the original HolyC behavior; malformed
expressions fail compilation. Assertions can inspect class offsets during member
parsing. Recursive lexer calls reuse an existing tracking record for their final
lookahead token, preventing duplicate ownership of that string. The header probe
distinguishes the existing count-only unused-forward warning for `CCPU` from
layout-assertion diagnostics; it accepts no failed layout assertion.

## Verification

The native probe loads the real headers in both boot and worker tasks. It starts
with a published forward `CTask`, rejects a header input followed by invalid
source, retries without losing that identity, and verifies repeated includes
allocate no retained state. Typed `Fs`/`Gs` read live task and CPU records.

It also reads the AOT layout fixture as native source and executes 108 assertions:
103 named non-padding task offsets, four record sizes and the dying-task wake
offset. Separate semicolons bound assertion-evaluation recursion. The original
x86-64 fixture still checks all 105 task fields, including both padding members.
Header fixtures remove their symbols and storage and verify complete heap,
compiler-control, task-reference, exception and interrupt-state recovery.

Command-input probes cover opt-in guard rollback/retry, repeated macro ordering,
callback exceptions, true/false assertions and invalid assertion expressions.
The console suite checks typed fields, a public task callback and repeated header
includes through keyboard input and exact VGA pixels. User-startup recovery also
checks that the public records remain available.

The larger development diagnostic suite has a 180-second startup allowance;
keyboard response deadlines remain unchanged. Standalone macro/token fixtures
can load up to 320 KiB below their existing first heap at `0x60000`, with an
explicit boot-loader bound for that memory map.

## Scope

Typed access exposes the live public records and their implemented fields, such
as self pointers, task signature, CPU binding, current symbol table and compiler
control links. Public stack descriptors now describe the actual contiguous
native stacks; see [stack ownership](i386-public-stacks.md). Full public allocation,
stack growth, task-family, document and debugger services are still incomplete. A field's presence does not establish its service
semantics. The private scheduler queues remain separate from public task links.

The remaining integration and hardware gates are in [PLAN.md](../PLAN.md).


## Shared circular-queue record

`Kernel/QueueTypes.HH` now holds the original complete `CQue` definition and its
help index, used by both `KernelA.HH` and native `PublicTaskTypes.HH`. Its guarded
include participates in the existing transactional public-header loading path.
The extraction preserves every other byte of the legacy-encoded kernel header.
No shortened or architecture-specific replacement record is introduced.

Five layout assertions verify each target: total size, next/last offsets and
next/last pointer widths. Original x64 values are 16, 0, 8, 8, 8; native values
are 8, 0, 4, 4, 4. The x64 task-layout check still verifies all 105 original task
fields. Native public-header checks now total 113 per boot/worker phase, including
rollback, retry and final reclamation. Two console submissions create a queue
record, set its self-links and retain a typed pointer across inputs.

Both x64 rebuild generations, the x64 layout check and the full native suite
pass. Normal boot executes 121 commands across 184 submitted lines with exact
VGA checks; startup recovery and all 17 module rejection cases also pass. Public
headers retain 67176 bytes (2600 more than before). Normal startup is 23.584
seconds and diagnostic startup 187.625 seconds on QEMU/486 with 8 MiB. Kernel
size remains 388928 bytes, leaving 192 bytes after the early stage in the fixed
reservation.

The record work is now followed by public `QueInit`, `QueIns`, `QueInsRev` and
`QueRem` in `Kernel/I386/Queue.HH`. These preserve the original U0 signatures and
four-byte links, including the removed entry's unchanged next/last values.
Five malformed declarations per boot/worker phase fail without publication or
heap changes. The shared nine-stage queue corpus passes on original x64, the
cross-generated runner and native boot/worker tasks.

With queue operations enabled, the full native suite passes 123 commands across
186 input lines. Public headers retain 71048 bytes. Normal startup is 24.988
seconds and diagnostics 220.877 seconds on the same QEMU/486 8 MiB profile.
The diagnostic worker now needs a temporary 512 KiB compiler arena; its teardown
returns 533664 bytes including stack and task metadata before console startup.
The shared document records are now available as described below; the full
DolDoc workflow remains unfinished.


## Help-file symbols

The queue header now uses its original `#help_file "::/Doc/Que"` directive.
Native command input publishes the help path, current help index and source
link as task-owned metadata. Public-header probes compare repeated directives
with original x64 behavior, test failed-input rollback and reclaim the complete
symbol graphs on boot and worker tasks. The public headers retain 71248 bytes,
200 more than before help metadata. See [help metadata](i386-help-metadata.md).


## Complete document records

PublicKernel now includes the canonical Kernel/DocTypes.HH used by the x64
kernel. The original eight records and all 131 x64 fields are preserved; native
CDoc is 680 bytes and CDocEntry is 160 bytes. Four original size assertions retain
eight-byte record strides through explicit tail alignment. CDocBin's saved span
is still 16 bytes, independently of its in-memory pointer width.

The native probe checks all 271 field/size assertions in batches, with unchanged
heap usage after each input, and runs the complete shared byte-span/callback
corpus. The editor's retained format metadata is also checked. Public headers
retain 169920 bytes. See [document records](i386-document-records.md) for the
layout contract and remaining service dependencies.
