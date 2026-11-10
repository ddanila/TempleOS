# Compiler-support document allocation at 8 MiB

The guarded-header/on-demand-lexer prototype still fails an 80-byte public
allocation during original User startup. A bounded frame-pointer diagnostic
identifies the allocation path, rather than inferring ownership from its size:

```
MemoryAlloc -> MemoryCAlloc -> NativeDocCAlloc -> DocEntryNewBase
  -> DocPutS -> DocLoad -> NativeIncludeDocumentCreate
  -> I386LexTaskFileInclude
```

The initial caller trace is in `build/public-alloc-caller-trace-v1/callers.json`.
Its public pool reports 0x100090 bytes used out of 0x100C00, with backing storage
fully used (0x118400). The exhausted request is 0x50 bytes. The trace does not
support the earlier hypothesis that this is a CJob allocation.

`docs/patches/i386-support-allocation-trace.patch` contains disposable diagnostic
instrumentation only. The memory trace uses the current task's stack bounds,
alignment checks, strictly increasing frame pointers and a limit of eight
frames. It allocates no trace buffers. It assumes a valid current task stack;
it is not a general fault handler or an alternate/debug-stack unwinder. Return
addresses must be decoded against the actual loaded module bases and kind-1
function export records. The desktop test's kind-3 data-symbol helper is not a
function symbol resolver.

A second probe logs the include filename immediately before invoking the
existing document creation callback. FileRuntime already imports KernelLog;
this adds no service/import ABI. It retains the prior traced memory module.
The candidate replaces only FileRuntime.t32m and matching TaskFileRead.HC over
the prior diagnostic image. Other files and boot bytes are checked unchanged.
The generated packaging receipt's copied human-readable scope describes the
first probe; its exact replacement checks and candidate hash describe the second.

This evidence does not qualify the original User prototype at 8 MiB. User
includes still need original rich-document behavior, including DolDoc handling;
a global switch to raw text would not establish compatibility. Resource gates,
production integration and two current native generations remain open.

## Filename probe result

`build/include-document-trace-v1` cross-compiles FileRuntime (281,804 bytes),
passes the complete module instruction audit, and reproduces the failure with
actual QEMU `-m 8`. The last includes are:

```
PublicOptSupport.HC -> SystemCompiler.HH -> SystemLoader.HH
LoadFlags.HH, PatchTypes.HH
CompilerA.HH -> IntermediateOpcodes.HH
PUBLIC ALLOC EXHAUSTED 0x50
```

The pool reports 0x1000F0 used out of 0x100C00, with backing storage still
fully used at 0x118400. CompilerA is entered because its guard is absent; this
is not proof that its declarations can be skipped. The immediate next resource
investigation is the cost of this nested document load, preserving the complete
compiler interface and original document semantics.

Candidate SHA256: `2d131351c78c13c9f922676875771310b988bf250ef7fcb567a448933d0840c4`.
User regression result SHA256: `d71fc733cf588fdb64be31dbefe2e3f8978d6748767bcaf70b0a9dfcb3ef224d`.
The expected failing result is retained, rather than reported as a passing
startup test. `evidence.json` checks receipt integrity and the precise final
include/failure sequence; it does not qualify runtime compatibility.
