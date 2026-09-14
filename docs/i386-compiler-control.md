# Native compiler-control lifetime

`CmpCtrlRelease` now shares the existing `CmpCtrlDel` destruction sequence between
x64 and native i386: release include files, discard saved lexer positions and
saved hash contexts, then free parser-stack storage, current string, help-index
string, dollar expansion and the control itself. Saved positions borrow source
payloads and do not release them a second time. Referenced symbol tables remain
borrowed. Code-generation queues retain their existing caller-managed lifetimes;
this change does not add parser/code-generation exception unwinding.

The x64 public `CmpCtrlDel` uses the shared routine with system allocation and
DolDoc release callbacks. Native allocation callbacks use an explicit arena and
preserve IF. Document callbacks run with the caller's interrupt state, with
exclusive ownership required across any callback or scheduler switch.

## Construction and destruction

`I386CmpCtrlNew` allocates a full `CCmpCtrl` followed by native heap/identity
metadata, an owned lexical root and a copied display name. `CmpCtrlSeed` supplies
the same flags, warnings, hash-table references and queue links as the public
constructor. `LexFileSeed` initializes the root's source pointers and line number.
The native file record is compatible with the existing include and EOF helpers.

The supplied filename is already resolved and the character bitmap already
selected by the caller. Public current-task symbol lookup, `FileNameAbs`, default
temporary filename and `CCF_KEEP_AT_SIGN` bitmap selection still belong in the
public construction wrapper; they are not silently replaced with new semantics.

Buffer ownership transfers only after successful construction. On any allocation
failure, the new control/file/name allocations are reclaimed and the input buffer
remains owned by its caller. An owned input must be a NUL-terminated allocation in
the selected heap. `CCF_DONT_FREE_BUF` permits a borrowed source instead.
`CCF_PMT` creates an eight-byte zeroed prompt buffer and leaves the supplied buffer
with its caller. Destruction preserves the original root-retention flag, including
the unusual `CCF_PMT | CCF_DONT_FREE_BUF` combination: its generated prompt buffer
must be retained and freed explicitly by the caller.

`I386CmpCtrlDel` validates native control identity and heap ownership. It rejects a
missing document callback before mutating an owned document stack. It then marks
the control as being destroyed and runs the shared release sequence. The complete
allocation graph must be valid, exclusively owned and free of aliases/cycles.
Arbitrary heap or graph corruption is not a transactional recovery contract.

## Retained integration and verification

CompilerRuntime version 18 retains constructor/destructor, task-symbol, active
queue, bounded unwind and temporary IR entries in its checked 108-byte record. Construction accepts an optional task owner. It imports native file creation and shared file release
from the kernel, avoiding another copy of file-stack mechanisms. The kernel now
publishes 43 bindings; the retained compiler has twenty imports.

The standalone disk-include probe creates a heap-owned control through this
retained interface in both boot and worker phases. It exercises nested plain and
compressed includes, malformed-input resumption, IF-set reading and destruction
with exact heap reclamation. Existing stack-based probes remain useful for
lower-level routines that accept caller-owned controls.

The lexical-state fixture checks constructor failure across small arenas with
borrowed and owned sources, seeded state, nested files and saved positions, saved
hash contexts, parser/string storage, foreign-heap rejection, document callback
requirements, prompt ownership and IF preservation. Its 256 KiB loader ends at
0x50000, the beginning of its existing arena. This test configuration does not
increase the standalone kernel's fixed bootstrap reservation.

Commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

These are compiler-lifetime integration checks on the QEMU/486 development
profile. Public task/code-heap policy, recoverable parser/JIT execution, actual
prompt/document input and native self-hosting remain required work.

The production disk probe now supplies the current task's symbol table and uses
its allocation heap. Children own local tables linked to their parent; see
[i386-task-symbols.md](i386-task-symbols.md). This connects scope selection for
the probe, while the complete public constructor wrapper remains unfinished.

The current-task factory now implements name/default-name and bitmap selection
and pins the task while its control survives. An optional owner argument leaves
unbound low-level construction available for isolated compiler uses. See
[i386-task-compiler.md](i386-task-compiler.md); active controls now drain on task exit with recoverable document-callback
rejection. Public heap/error behavior and parser unwind remain open.

Explicit catch-boundary cleanup now preserves enclosing active controls; see
[i386-compiler-unwind.md](i386-compiler-unwind.md).

Native destruction now releases current and saved intermediate-code contexts
before input/control release. Shared graph release handles all eight auxiliary
kinds and their owned payloads; see [i386-code-context.md](i386-code-context.md).

Copied code headers can alias IR. Native cleanup now uses a separate allocation
registry rather than traversing each header as an independent owner; see
[i386-code-views.md](i386-code-views.md).
