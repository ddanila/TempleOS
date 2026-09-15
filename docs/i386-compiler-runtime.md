# Retained compiler runtime in extended memory

CompilerRuntime now requires ABI 37 (200 bytes) because expression services add
an optional private class-view callback for [class completion](i386-class-completion.md).
The outer service-table size is unchanged; callers supplying expression services
must initialize the new callback.

The bootstrap kernel no longer contains the quoted-string/number/character/operator decoders,
software F64 implementation or power table. `Kernel/I386/CompilerRuntime.HC`
builds them into a separate `CompilerRuntime.t32m` disk module. Native startup
loads it through the checked RedSea/module loader into the extended-memory heap,
initializes a versioned interface, and retains its image for the kernel lifetime.
This removes the current compiler-runtime growth from the conventional-memory
boot stage without increasing that stage's 384 KiB reservation.

The build still links six bootstrap modules. It packages four additional modules:
CompilerRuntime and FileRuntime are retained, Startup is reclaimed after initializing the display,
and CompilerProbe is retained through the boot/task checks and then reclaimed.
All ten modules have
separate hashes and executable-range instruction audits. The manifest distinguishes
bootstrap modules from all resident modules.

## Interface and provider lifetime

`CompilerRuntime.HH` defines version 31 of CI386CompilerServices: a U32 version,
U32 byte count, and native function pointers for string chunks, numeric tokens, character constants, punctuation, identifier scanning,
identifier-token completion, owned string tokens, mixed-token dispatch, dispatch
with an explicit include provider, compiler-control construction/destruction,
root task-symbol initialization, and active-control entry/leave/drain, bounded unwind, and temporary IR allocation/discard, saved-header operations, instruction retirement, shared branch optimization and pass 0/1/2 constant folding/type analysis owned output buffers and shared function lowering.
The current structure is 184 bytes on i386; later entries add owned parser
services, class publication and scalar bootstrap as described below. The entry receives caller-owned interface
storage and its capacity, rejects missing storage or the wrong size, and publishes
these fields only into that caller's candidate record. It does not retain the
address of the candidate record or allocate an interface object.

The module imports nineteen kernel functions: I386LexRawChar, I386LexSourceRead,
HashFind, HashAdd, StrCmp, I386HeapAlloc/Free/Size, I386IrqSave/Restore, I386LexIncludeCopy, I386LexFilePush, LexFileReleaseTop, and
I386HashTableNew/Valid/Delete, throw, SysTry and SysUntry,
and four kernel data arrays: char_bmp_hex_numeric, char_bmp_dec_numeric and
char_bmp_non_eol and char_bmp_non_eol_white_space. The
latter remain the same writable public tables used by the kernel; moving the
runtime does not create private copies. Kernel bindings use the existing shared
CHashExport prefix and distinguish function from data addresses. The module keeps
its own numerical implementation and immutable-use power table inside its image.

KernelCompilerLoad runs with IF clear and exclusive disk/heap ownership. After
loading, the kernel verifies one retained allocation, extended-memory placement,
interface version and byte count, and that all service pointers fall inside the
loaded image. It publishes the global interface only after these checks succeed.
The host boot verifier independently checks all pointer values against the
module's actual function export offsets, not just the image's address range.

The image, its code/data and the kernel providers must remain live for every
service invocation. Local binding tables and input-file buffers may be retired
after relocation. The kernel deliberately retains the image and exposes no unload
operation: all users would first need to stop and detach every borrowed code/data
reference. This is an explicit boot lifetime, not a general unload dependency or
reference-counting implementation. The ring-0/shared-address-space trust model is
unchanged; pointer bounds and file validation do not make arbitrary module code
untrusted or isolated.

A failed load or incompatible returned interface reclaims temporary/image storage
and verifies the heap returns to its pre-load byte/allocation counts before
reporting failure. The interface remains unpublished. Module initialization is a
trusted, synchronous operation; it must not leave unrelated side effects or retain
caller storage before reporting success.

## Execution and verification

KernelCompilerProbe invokes the separate CompilerProbe module, which calls the
actual relocated services during boot and again
from the pulse task after startup, VGA allocation, task creation and timer IRQs.
It parses a software-F64 numeric token, a hexadecimal string escape and a packed character constant, then skips a line comment, parses a shift assignment and resolves an identifier
from an owned copied include. The source crosses back to a cached parent delimiter
and reclaims the child record/name/buffer.
It checks
returned values and input positions, verifies no transient heap allocation remains,
and checks that the retained image is still a live allocation of the original
size. Boot source consumption remains a separate raw-character pass.

Run:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-string
python3 tools/test-i386.py --lex-ident
python3 tools/test-i386.py --lex-tokens
python3 tools/test-i386.py --lex-define
python3 tools/test-i386.py --lex-cond
python3 tools/build-i386-kernel.py --test
```

Both x86-64 rebuild/reboot generations, the string/identifier regressions and the full boot
suite pass. Three runtime rejection boots alter its CPU tag, one function import,
and its returned interface version respectively. All halt before interface use or
startup execution and report reclamation. The existing startup rejection cases,
keyboard/scrolling/cancellation pixel checks, source checks and timer checks pass;
each test's disk remains unchanged.

Version 10 appends next_token_with_includes, which calls the shared native lexer
with the supplied synchronous provider. The original next_token remains available
without a provider. No callback or context is stored in the retained runtime.
The provider's code and context must remain live for the complete call, including
recursive include and conditional reads. The kernel validates the new address
before publication, and the host matches it to I386RuntimeLexIncludes's export.
The wrong-version boot now supplies version 9 and verifies rejection/reclamation.

ProbeIncludes calls the relocated service with a callback in the temporary probe
module. It reads nested children producing 11, 22 and 33, skips an inactive missing
include, returns to the parent delimiter and reaches EOF. A subsequent missing
include returns an error and resumes at parent value 44. The old providerless
entry rejects an include without invoking the previous callback. The probe checks
interrupt-state preservation, owned input/token reclamation and runtime liveness.
INCLUDE PROBE records are required before startup and after task/IRQ activity;
all temporary callback use ends before the probe image is freed.

At version-10 introduction: bootstrap 384208 bytes of the 393216-byte
reservation, leaving 9008 bytes. The retained runtime has 138664 image bytes and
138680 heap bytes. The temporary diagnostic image has 59760 bytes and reclaims
its entire 59776-byte heap span after the task call. Source consumption verifies
25871 characters and 551 newlines with 26448 reclaimed heap bytes. These are
measurements recorded in result.json, not fixed addresses or memory minima.
The 73 keyword records retain 6208 bytes behind primitive types in symbol lookup.

Disk-backed include loading now uses retained FileRuntime and is exercised through
this interface during boot. The task phase verifies enabled-IF rejection; it
performs no disk I/O. See `i386-file-runtime.md` for current memory measurements
and the remaining scheduler/public-file integration. See [include dispatch](i386-lex-includes.md),
[compiler diagnostics](i386-compiler-probe.md) and
[file input](i386-file-context.md) for the remaining integration boundaries.

## Import-declaration correction

This integration exposed an existing parser lifetime error. PrsFunJoin can reuse
a prior function declaration and free the incoming name. The unaliased import
branch subsequently copied that freed pointer, yielding a debug source location
as the raw-reader import name in the emitted module. It now copies tmpf->str, the
retained canonical symbol name. The resident-binding consumer now declares its
function as extern before importing it, covering the same declaration sequence.

The loaded module supplies lexer/numerical components, not a resident full compiler
or JIT. Remaining compiler modules can use this extended-memory placement path,
but complete lexical integration, target-aware literal evaluation, public task/
allocation/file APIs, editing/DolDoc, native rebuild/self-hosting and strict 386
validation remain required. QEMU/486 execution with CR0.EM and instruction audits
is development evidence, not proof of every 386SX/DX machine profile.

Version 11 adds owned compiler controls. The constructor shares full control/file
initialization, and destruction shares the public x64 release sequence. The disk
probe now creates and destroys its control through retained service pointers in
both boot and worker phases, with exact heap reclamation after nested includes
and malformed-input recovery. See [i386-compiler-control.md](i386-compiler-control.md)
for source ownership, failure rollback, document callbacks and remaining public
wrapper integration. The retained runtime is now 151096 image bytes / 151112 heap
bytes. The native bootstrap is 386608 bytes; with the 2160-byte loaded stage it
leaves 4448 bytes in the unchanged reservation.

Version 12 installs task-owned symbol scopes. Children have independent local
tables chained to a pinned parent, with owned entries reclaimed using the public
symbol-release policy. The disk compiler probe uses the current scope and its
heap; see [i386-task-symbols.md](i386-task-symbols.md) for lifetime and allocation
contracts. Public constructor/name/bitmap and complete task heap policy remain
separate integration work.

Version 13 adds a task-owner argument to control construction without changing
the 56-byte record size. A successfully bound control pins the task until complete
destruction, including document callbacks. FileRuntime version 4 now supplies the
current-task factory and context selection. See
[i386-task-compiler.md](i386-task-compiler.md). CompilerRuntime now uses 176336
image bytes / 176352 heap bytes; the native kernel is 389800 bytes and leaves
1256 bytes after its loaded stage in the unchanged bootstrap reservation.

Version 14 adds active-control entry, leave and task-exit drain in the retained
module. The interface is 68 bytes with the same twenty imports. The native task
record owns the queue and calls back into the provider at completion; controls
remain detached until explicitly entered. FileRuntime version 5 validates the
new dependency. See [i386-task-compiler.md](i386-task-compiler.md) for recovery,
callback and owner-pin contracts.

Version 15 adds explicit unwind to an enclosing active control, preserving that
control and earlier entries. Full task-exit drain uses the same operation with
the queue sentinel. The record is 72 bytes and imports remain twenty. The disk
probe now recovers through native `try`/`catch`, preserves its enclosing control
and tokenizes fresh input after a malformed include. See
[i386-compiler-unwind.md](i386-compiler-unwind.md) for ownership and coverage.

Version 16 adds temporary instruction/auxiliary allocation and graph discard in
an 84-byte record. Code contexts share initialization and payload release with the
public parser. Native control destruction now releases active and saved code
contexts, so catch-boundary and task-exit cleanup reclaim their temporary IR too.
FileRuntime version 7 validates the new dependency. See
[i386-code-context.md](i386-code-context.md) for ownership, diagnostics and tests.

Version 17 separates IR allocation ownership from aliased or detached code-header
views and exposes save/push/pop/header-free/append. Discard now accepts an optional
diagnostic callback/context. The interface is 104 bytes with twenty imports;
FileRuntime version 8 validates it. See [i386-code-views.md](i386-code-views.md) for
original parser patterns, cleanup guarantees and remaining public integration.

Version 18 adds native instruction retirement to preserve optimizer tree references
after queue removal. Complete discard can reclaim retired nodes once no other code
allocations remain. The record is 108 bytes, still with twenty imports; FileRuntime
version 9 validates it. See [i386-ir-retirement.md](i386-ir-retirement.md).

## Native shared branch optimization (version 19)

The 112-byte record appends `code_branch`, executing the shared zero/nonzero
branch transformations with native instruction retirement and label allocation.
`throw` raises the import count to twenty-one. FileRuntime version 10 validates
the dependency. Partially rewritten graphs remain owned for exception cleanup;
see [i386-branch-optimizer.md](i386-branch-optimizer.md).

## Native shared constant folding (version 20)

The 116-byte record appends `code_optimize`, executing the shared OptPass012 core
with native stack ownership and diagnostics. FileRuntime version 11 validates the
new dependency. Opcode metadata initializes before service publication; numerical
helpers and imports remain within the existing retained provider contract. See
[i386-constant-optimizer.md](i386-constant-optimizer.md).

## Native owned output buffers (version 21)

The 124-byte record appends `out_new` and `out_del`. The output carries its native
reserve callback; byte emission is shared with the cross-host backend. Control
unwind reclaims the builder and its current byte storage. FileRuntime version 12
validates the new compiler contract. See
[i386-code-emitter.md](i386-code-emitter.md).

## Shared native function lowering (version 22)

The 128-byte record appends `backend`. Its shared lowering loop receives explicit
type, allocation, folding, assembly and diagnostic services. Native temporary and
relocation allocations belong to the compiler control. FileRuntime version 13
validates this dependency. See [i386-native-backend.md](i386-native-backend.md) for
the private AOT/symbol-context and output-lifetime contracts.

## Retained scalar bootstrap (version 30)

The current interface includes native expression/type/declaration/class parsing,
parser allocation/token ownership and durable class publication. It adds a retained
frontend context and services for loading the original six scalar unions into the
root task's symbol table. Controls and temporary parser state are reclaimed while
published class graphs remain live through worker execution and probe-module
release. See [i386-scalar-bootstrap.md](i386-scalar-bootstrap.md) for contracts,
source metadata, failure recovery and remaining frontend limitations.

## Owned frontend expression output (version 31)

The `frontend` entry returns the retained parser services for an owned active
control. Expression outputs carry their literal pools and remain registered until
explicit release or control unwind. Native software-F64 calls are linked to the
retained runtime, and the shared function-header parser can evaluate numeric and
string defaults. See [i386-frontend-expressions.md](i386-frontend-expressions.md).

## Private statement and function compilation (version 32)

The 188-byte interface appends `statement`, composing the complete shared
statement/function/initializer grammar with the retained frontend. Private JIT
functions, globals and static storage remain control-owned. Calls use private
relocation descriptors, and successful or failed compilation must support full
control cleanup. See [i386-native-statements.md](i386-native-statements.md) for
the supported integration paths, lifetime rules and remaining public-shell work.

## Top-level command compilation (version 33)

The 192-byte interface appends `command`. It compiles one shared-parser statement
while preserving global declaration scope and the caller's IR. Registered outputs
use the existing execution/release providers; private definitions remain available
throughout the input control's lifetime. See
[i386-native-commands.md](i386-native-commands.md) for result, load-only and failure
semantics and the remaining persistent-session work.

## Task-owned program publication (version 34)

The 196-byte interface appends `publish`. Complete private symbol graphs move to
the current task's table, and executable/static allocations move to its separate
storage list. Definitions survive compiler-control destruction and remain usable
after a later control fails. See
[i386-program-publication.md](i386-program-publication.md) for transfer validation,
teardown, retained literal pools and remaining replacement/unload constraints.

## Submitted source input

ABI 35 (200 bytes) appends `input`, the synchronous source-buffer lifecycle entry.
It owns a private compiler control through parsing, execution, publication and
cleanup, with borrowed result/diagnostic callbacks and load-only support. See
[command input](i386-command-input.md) for ownership and exception contracts.
