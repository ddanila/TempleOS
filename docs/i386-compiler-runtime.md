# Retained compiler runtime in extended memory

The bootstrap kernel no longer contains the quoted-string/number/character/operator decoders,
software F64 implementation or power table. `Kernel/I386/CompilerRuntime.HC`
builds them into a separate `CompilerRuntime.t32m` disk module. Native startup
loads it through the checked RedSea/module loader into the extended-memory heap,
initializes a versioned interface, and retains its image for the kernel lifetime.
This removes the current compiler-runtime growth from the conventional-memory
boot stage without increasing that stage's 384 KiB reservation.

The build still links six bootstrap modules. It packages three additional modules:
CompilerRuntime is retained, Startup is reclaimed after initializing the display,
and CompilerProbe is retained through the boot/task checks and then reclaimed.
All nine modules have
separate hashes and executable-range instruction audits. The manifest distinguishes
bootstrap modules from all resident modules.

## Interface and provider lifetime

`CompilerRuntime.HH` defines version 9 of CI386CompilerServices: a U32 version,
U32 byte count, and native function pointers for string chunks, numeric tokens, character constants, punctuation, identifier scanning,
identifier-token completion, owned string tokens and mixed-token dispatch.
The structure is 40 bytes on i386. The entry receives caller-owned interface
storage and its capacity, rejects missing storage or the wrong size, and publishes
these fields only into that caller's candidate record. It does not retain the
address of the candidate record or allocate an interface object.

The module imports eleven kernel functions: I386LexRawChar, I386LexSourceRead,
HashFind, HashAdd, StrCmp, I386HeapAlloc/Free/Size, I386IrqSave/Restore and I386LexIncludeCopy,
and four kernel data arrays: char_bmp_hex_numeric, char_bmp_dec_numeric and
char_bmp_non_eol and char_bmp_non_eol_white_space. The
latter remain the same writable public tables used by the kernel; moving the
runtime does not create private copies. Kernel bindings use the existing shared
CHashExport prefix and distinguish function from data addresses. The module keeps
its own numerical implementation and immutable-use power table inside its image.

KernelCompilerLoad runs with IF clear and exclusive disk/heap ownership. After
loading, the kernel verifies one retained allocation, extended-memory placement,
interface version and byte count, and that all eight service pointers fall inside the
loaded image. It publishes the global interface only after these checks succeed.
The host boot verifier independently checks all eight pointer values against the
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

With conditional preprocessing in interface version 9, the bootstrap image is
372288 bytes of its 393216-byte reservation. The 135952-byte runtime image
is allocated at 0x135B80 in the 8 MiB development profile and retains a
135968-byte heap span. All eight service addresses match their exported offsets.
Boot/task probes expand a macro, publish its identifier, replace that text with a
binary string and free it. They also define a new macro from source, expand it to
F64, consume the delimiter/EOF, detach the definition and reclaim its owned
record/name/body/source link. DEFINE PROBE records are required in both phases,
alongside the existing IDENT PROBE, STRING PROBE and LEX PROBE records.
Version 9 also selects nested symbol-conditional branches through the real keyword
and primitive namespace, with CONDITIONAL PROBE records required in both phases.

Source checks cover 25613 characters, 550 newlines, FNV32 0x6B3D88F3 and
26072 reclaimed heap bytes. Sizes and addresses are observations from result.json,
not fixed addresses or memory minima required by the interface. After native
keyword initialization, the bootstrap has 20928 bytes of headroom. The 73 keyword
records retain 6208 heap bytes and sit behind primitive types in symbol lookup.
Definition probes now use that actual namespace, without a synthetic keyword.
The temporary probe image is 48232 bytes, and its 48248-byte heap span is
released after its second call; the compiler runtime and keyword registry remain
resident. See [keyword initialization](i386-keywords.md),
[compiler diagnostics](i386-compiler-probe.md) and
[native definition handling](i386-lex-define.md) for ownership and remaining work.

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
