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

CompilerRuntime version 11 adds constructor/destructor entries to its checked
52-byte service record. It imports native file creation and shared file release
from the kernel, avoiding another copy of file-stack mechanisms. The kernel now
publishes 37 bindings; the retained compiler has seventeen imports.

The standalone disk-include probe creates a heap-owned control through this
retained interface in both boot and worker phases. It exercises nested plain and
compressed includes, malformed-input resumption, IF-set reading and destruction
with exact heap reclamation. Existing stack-based probes remain useful for
lower-level routines that accept caller-owned controls.

The lexical-state fixture checks constructor failure across small arenas with
borrowed and owned sources, seeded state, nested files and saved positions, saved
hash contexts, parser/string storage, foreign-heap rejection, document callback
requirements, prompt ownership and IF preservation. Its 192 KiB loader ends at
0x40000, the beginning of its existing arena. This test configuration does not
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
