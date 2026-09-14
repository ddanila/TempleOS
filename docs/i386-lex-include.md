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

Owned token strings, ordinary lexical dispatch, definitions and symbol/mode
conditionals now have native component coverage. Remaining preprocessing, native
parser/JIT, public runtime ownership, DolDoc, self-hosting and strict 386 hardware
verification remain required.

## Transfer of an existing source allocation

`I386LexIncludeTake` accepts a distinct source allocation already owned by the
supplied heap. It copies the diagnostic name and allocates the native file record,
then transfers source ownership only after both allocations succeed. It shares
publication with `I386LexIncludeCopy`, including parent lookahead backup. The
caller must free the source on failure and must relinquish it on success.

The allocation must contain at least one byte and end in NUL. Interior pointers,
foreign/static storage, unterminated allocations, and known aliases to the active
control, token text or file-stack records/names/buffers are rejected. The caller
remains responsible for exclusive ownership and avoiding other aliases. Embedded
NUL bytes are permitted in storage; lexical EOF still follows the original input
semantics. The name remains borrowed during the call and is copied before source
ownership transfers.

The lexer-state fixture verifies identical source pointers and exactly two new
allocations on success, copied metadata, line accounting, parent replay, saved
position rejection at child EOF, empty-child handling and complete reclamation.
Thirteen small arenas exercise failure before record/name publication while
preserving ownership and input state. Invalid modes, allocations and known aliases
are rejected; both interrupt states are preserved. The fixture now uses a 160 KiB
loader reservation with its heap still at 0x40000; the OS bootstrap and hardware
memory targets are unchanged.

This prepares disk-loaded input without a second source-sized copy. Public path
and extension semantics, decompression and include-directive dispatch still need
to connect file reading with this ownership boundary.

KernelStorage now transfers its RedSea-loaded source into a child above an empty
borrowed root. Boot checks every returned character's child/line context, hashes
all source bytes, crosses EOF back to the root and verifies the source allocation
was reclaimed before disposing of the root/control. The measured transient span
includes the child and copied filename (120 additional bytes), rather than a
second full source allocation.

The original include directive applies `ExtDft(name,"HC.Z")` and `FileNameAbs`.
Public `FileRead` additionally tries the toggled .Z name, searches parent
directories and consults/populates resident file records before decompression.
A native directive must preserve those behaviors through file services rather
than treating exact-volume lookup alone as public FileRead compatibility.
