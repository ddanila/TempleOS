# Owned native source attachment

I386LexIncludeCopy attaches a copied raw source buffer above an existing lexical
file. The caller supplies a live control, explicit heap, diagnostic name, source
string and optional define marker. Name and source remain borrowed during the
call and are never adopted or freed. The new file owns independent copies of both
strings plus its native owner record; ordinary native EOF/pop handling releases
all three allocations.

The helper requires an active parent and raw input support. Null name/source and
prompt, echo or document input modes are rejected. Names are already selected by
the caller: this function does not resolve paths, read a disk file or choose the
legacy temporary diagnostic filename for macro expansion.

All three allocations complete before any parent/control state changes. Failure
unwinds temporary allocations and returns false, preserving the active file,
cursor, replay flags and cached parent lookahead. Success copies the strings,
sets ownership/name/buffer/line/define fields, backs up the parent through the
shared LexBackupLastChar rule, links the child and publishes its input cursor.
Both allocation and publication use short interrupt-masked sections; string copies
run with the caller's interrupt state restored. The control and borrowed strings
must remain exclusively owned/live throughout the operation.

LexBackupLastChar now resides with the shared file-stack helpers, so snapshot and
include paths use one implementation. Its legacy narrowing of cached lookahead to
the CLexFile byte field is unchanged. A successful include keeps parent payloads
live, records parent cursor/replay and gives the child depth parent+1 and line 1.
An empty child resumes the parent through the existing raw-reader logic.

Pending save points are retained by attachment. Native EOF pop still rejects a
live save point, leaving the child owned and active until the caller releases the
save point and resumes/restarts appropriately. This preserves the existing native
ownership restriction; general parser lookahead across include boundaries still
needs integration. The helper alone is not macro expansion or preprocessing.

## Verification

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-ident
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

The identifier fixture tests independent copies, define flags, line/depth fields,
parent cursor/replay, nested and empty children, cached-byte narrowing, pending
save-point rejection/release, and complete reclamation. Arena sizes 32..224 in
8-byte increments span allocation failure and success; failed attachment must
preserve parent/control state and recover all temporary heap storage. Calls from
both IF states verify restoration.

The kernel's retained-runtime identifier probe now attaches an owned I64i source
above a parent with a cached semicolon. The resident scanner crosses that EOF,
reclaims the child and resolves the live primitive symbol before startup and after
task activity, with the original heap baseline restored. This exercises the
attachment and retained reader/lookup together without treating the probe as a
complete native lexer.

Owned token strings, full lexical dispatch and macro/directive execution, native
parser/JIT, public runtime ownership, DolDoc, self-hosting and strict 386 hardware
verification remain required.
