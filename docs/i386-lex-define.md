# Shared definition replacement-text reader

`Compiler/LexDefine.HC` extracts the replacement-text reader used by the production
`#define` directive. The x86-64 lexer still recognizes the directive/name, allocates
and publishes CHashDefineStr, records source metadata, and controls NO_DEFINES.
It now delegates replacement-text reading to `LexDefineRead` with its existing
character reader and an allocating append callback.

The reader starts after the name token, with its delimiter lookahead still
pending. It skips leading non-EOL whitespace and retains the original continuation,
quote, comment, replay, EOF and chunk-boundary behavior. Every appended chunk
includes a NUL; the callback replaces the previous chunk's NUL when growing the
text. This preserves the original allocation lengths and byte-copy semantics.
The callback owns any accumulated text, including partial output on failure.
Negative character reads and rejected appends return FALSE. Failed reads are not
retried or converted into successful EOF; input and replay state are not rewound.

`I386LexDefineBody(heap, cc, compiled_lines)` supplies the native raw reader and
heap builder. It returns an exact-sized, heap-owned NUL-terminated buffer, including
one byte for an empty definition. It frees partial construction on reader or
allocation failure and returns zero. Heap operations use short interrupt-masked
sections; byte copies run outside them. The function does not alter token/name
ownership or publish a hash entry. As with existing token builders, repeated
reallocation can have quadratic copying cost; low-memory compiler integration must
measure this before claiming the full memory target.

Compatibility checks use 29 fixed input/output pairs, including sizes around the
140-byte flush boundary and a 2048-byte body. They passed through the actual
production `#define` lexer at 6841633 before extraction (`build/define-original.log`).
They cover whitespace, CR/LF continuation, quoted and unquoted double slashes,
block-comment text, escaped quotes, slash lookahead and EOF. Two non-obvious legacy
behaviors are retained: a double slash at the very start of replacement text is
kept, and an EOF backslash is retained initially but dropped after ordinary text.
These are compatibility observations, not a new language specification.

The dedicated --lex-define fixture compares the same expectations with native construction.
It injects a failure at each character read and each append in all 29 cases,
checks continuation cursor/line state, rejects prompt input, and exercises 253
heap arenas from 32 to 2048 bytes. Both successful construction and failed partial
construction must reclaim every allocation. The runner reports one aggregate
Main result containing the replacement-text and directive tests. The separate
--lex-tokens suite retains mixed-token coverage; both keep the 256 KiB loader
limit and heap at 0x60000.

Run:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-define
python3 tools/test-i386.py --lex-tokens
python3 tools/build-i386-kernel.py --test
```

Both x86-64 rebuild/reboot generations, the expanded mixed-token fixture and its
instruction audit, and the full native kernel boot suite pass.

## Definition publication and dispatch

I386LexDefinePublish requires an already recognized identifier token, live input
with a full_name, a writable definition hash table and heap-owned cur_str. It
builds a zeroed CHashDefineStr, copies `FL:filename,line` source metadata and any
nonempty help index, preserves KEEP_PRIVATE and sets cnt=-1. It captures metadata
before reading the body, so an owned include can reach EOF and be reclaimed
without leaving a dangling filename reference. Source lines retain their I64 width
and are clamped to one when negative or zero, matching HashSrcFileSet.

The name moves from cc.cur_str to the entry only after all construction succeeds.
HashAdd then publishes the complete entry. Allocation/input failure reclaims the
partial entry, body and metadata while leaving the previous name and hash table
intact. Input consumption is not rolled back. The owner must detach symbols and
borrowed references before I386HashDel releases their storage. Redefinition keeps
older entries in the chain with the original lookup precedence.

I386LexNext now recognizes KW_DEFINE through the caller's keyword symbol table,
uses NO_DEFINES while reading the name, invokes publication, then resumes token
dispatch. The keyword constants are shared in Compiler/Keywords.HH. A malformed
non-identifier name follows the existing skip-and-resume behavior; native service
failures return an explicit error and clear NO_DEFINES. Unsupported directives
still return -4, now after reading the directive token; any published token text
remains owned by the caller. KEEP_SIGN_NUM continues to return a literal hash.

Shared x64/native tests exercise definition and expansion, redefinition, empty
bodies, EOF, local shadowing, source/help metadata, private flags and line numbers
above 32 bits. Native cases cover publication failures across 253 heap arenas,
name-allocation failure through the dispatcher, and metadata surviving an owned
include's EOF/pop. Cleanup uses the existing symbol destructor.

CompilerRuntime version 8 keeps the eight-pointer, 40-byte interface and adds
HashAdd and char_bmp_non_eol_white_space imports. Its kernel probes define a macro,
expand it to F64, consume the parent delimiter/EOF and reclaim the definition both
at boot and after task/timer activity. General keyword-table initialization,
includes, conditionals, executed directives, prompt/document input and complete
compiler-control lifetime still need integration before native preprocessing is
complete.
