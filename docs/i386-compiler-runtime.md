# Retained compiler runtime in extended memory

The bootstrap kernel no longer contains the quoted-string/number decoders,
software F64 implementation or power table. `Kernel/I386/CompilerRuntime.HC`
builds them into a separate `CompilerRuntime.t32m` disk module. Native startup
loads it through the checked RedSea/module loader into the extended-memory heap,
initializes a versioned interface, and retains its image for the kernel lifetime.
This removes the current compiler-runtime growth from the conventional-memory
boot stage without increasing that stage's 384 KiB reservation.

The build still links six bootstrap modules. It packages two additional modules:
CompilerRuntime is retained, while Startup initializes the display and is then
reclaimed under its existing synchronous-entry contract. All eight modules have
separate hashes and executable-range instruction audits. The manifest distinguishes
bootstrap modules from all resident modules.

## Interface and provider lifetime

`CompilerRuntime.HH` defines version 1 of CI386CompilerServices: a U32 version,
U32 byte count, and native function pointers for string chunks and numeric tokens.
The structure is 16 bytes on i386. The entry receives caller-owned interface
storage and its capacity, rejects missing storage or the wrong size, and publishes
these fields only into that caller's candidate record. It does not retain the
address of the candidate record or allocate an interface object.

The module imports two kernel functions, I386LexRawChar and I386LexSourceRead,
and two kernel data arrays, char_bmp_hex_numeric and char_bmp_dec_numeric. The
latter remain the same writable public tables used by the kernel; moving the
runtime does not create private copies. Kernel bindings use the existing shared
CHashExport prefix and distinguish function from data addresses. The module keeps
its own numerical implementation and immutable-use power table inside its image.

KernelCompilerLoad runs with IF clear and exclusive disk/heap ownership. After
loading, the kernel verifies one retained allocation, extended-memory placement,
interface version and byte count, and that both service pointers fall inside the
loaded image. It publishes the global interface only after these checks succeed.
The host boot verifier independently checks both pointer values against the
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

KernelCompilerProbe calls the actual relocated services during boot and again
from the pulse task after startup, VGA allocation, task creation and timer IRQs.
It parses a software-F64 numeric token and a hexadecimal string escape, checks
returned values and input positions, verifies no transient heap allocation remains,
and checks that the retained image is still a live allocation of the original
size. Boot source consumption remains a separate raw-character pass.

Run:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --redsea-bind
python3 tools/build-i386-kernel.py --test
```

Both x86-64 rebuild/reboot generations, the binding regression and the full boot
suite pass. Three runtime rejection boots alter its CPU tag, one function import,
and its returned interface version respectively. All halt before interface use or
startup execution and report reclamation. The existing startup rejection cases,
keyboard/scrolling/cancellation pixel checks, source checks and timer checks pass;
each test's disk remains unchanged.

At this revision, the bootstrap image is 346912 bytes, down from 384664. The
52520-byte runtime image is allocated at 0x11F008 in the 8 MiB development profile
and retains a 52536-byte heap span. Both service addresses match their relocated
export offsets, and both boot/task probes return the expected values. Raw source
checks cover 19309 characters, 454 newlines, FNV32 0x5D4679C6 and reclamation of
19768 temporary heap bytes. These sizes and addresses are observations recorded
in the manifest, not fixed addresses or memory minima required by the interface.

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
