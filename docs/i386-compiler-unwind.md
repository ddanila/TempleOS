# Native compiler unwind boundaries

`I386CmpCtrlUnwind(task, boundary)` releases the active controls after a live
boundary, from the tail toward that boundary. The boundary itself and all earlier
controls survive. Passing `&task->next_cc` selects the whole queue; task-exit drain
uses this same operation. An empty suffix succeeds without requiring a document
callback for the preserved boundary.

This is an explicit compiler cleanup operation, not an automatic action on every
`throw`. The public compiler catches exceptions while using existing controls
(for example, `CmpJoin` and `ExePutS` in `Compiler/CMain.HC`). A generic exception
hook that deleted all controls before invoking those catches would invalidate
that state. A compiler entry/catch must choose and keep its enclosing boundary
live until cleanup completes. Queue mutations and object lifetimes remain under
the caller's exclusive ownership; the boundary is not a durable handle that can
be retained after deletion or address reuse.

## Ownership and failure behavior

The caller must be the current owner, or have exclusive access to a finished
owner for recovery. The boundary must be an active control of that owner or its
queue sentinel. Null, detached and absent boundaries are rejected. Traversal is
bounded by the active count and validates each selected control and its links.

All controls selected for release are checked for required document callbacks
before any mutation. A missing callback preserves the complete selected suffix,
its owner pins and heap allocations. Missing document cleanup in the preserved
prefix does not prevent releasing a valid suffix. The callbacks registered at
entry are used for release; explicit deletion may supply a missing callback.

Release holds the owner busy and pinned through callbacks, which may yield but
must return normally. Reentrant mutations of that owner's controls are rejected.
Caller IF is preserved. Successful partial recovery of a finished task leaves
its existing cleanup-failure flag set while active controls remain; releasing the
last active control clears it. Full drain and task-exit cleanup retain their
previous ownership and reaping rules.

The shared control release sequence covers its owned input/include records,
saved lexer and hash contexts, parser-stack allocation and temporary strings.
It now also releases current and saved code-context graphs using the shared
parser payload policy; see [i386-code-context.md](i386-code-context.md). It does not
independently reclaim caller-owned symbol tables, generated code or all AOT graphs. Wiring their existing release policies into native parser
failure paths is still required before claiming a recoverable native compiler.

## Retained integration and verification

CompilerRuntime version 17 exposes `control_unwind` in its 104-byte service table;
its twenty imports are unchanged. FileRuntime version 8 validates the new compiler
dependency, retaining its 32-byte record and eighteen imports. CompilerProbe
version 4 imports the kernel's resident `SysTry`, `SysUntry` and `throw` in addition
to its previous thirteen bindings. The kernel export index now has 43 entries.
These records remain bootstrap interfaces, not a new application API.

The standalone disk probe keeps an enclosing active control, creates a child
control, and reads a malformed compressed include through the retained lexer and
file services. Its test caller translates the explicit lexer failure into a
`Compiler` exception. Native `try`/`catch` invokes the unwind service, preserving
the enclosing input/control and releasing the child. A new child then tokenizes
`42;`, proving the same task can reuse the services after recovery. Both boot/IF
clear and worker/IF set paths verify exception-record removal, owner references
and exact heap reclamation. The lexer itself still returns its existing error
status; this does not implement public compiler diagnostics or native JIT.

The task-symbol fixture checks full preflight before mutation, a preserved outer
document without a callback, detached/null boundary rejection, empty suffixes,
callback yields/reentry rejection, and partial recovery of a finished owner.
It runs these ownership paths with IF clear and set, alongside existing task-exit
and detached-lifetime tests. The lexer-state regression checks low-level unbound
control ownership remains usable.

Verification commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --task-symbols
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

These are QEMU/486 development checks with executable-region instruction audits.
Strict 386SX/DX/no-387 execution, public heap/error policy, complete parser/JIT
recovery and native self-hosting remain open.
