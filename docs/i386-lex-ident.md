# Shared identifier scanning and lookup

The production x86-64 lexer and native I386LexIdentScan use LexIdentRead and
LexIdentFind. The scanner copies the already-consumed first byte, recognizes
continuations through the control's writable alphabet bitmap, maps script tokens
to greater/less/equal characters, and preserves delimiter replay and EOF behavior.
The x86-64 caller still supplies STR_LEN (144), retaining the 143-byte identifier
limit and the existing diagnostic before reading beyond that limit.

LexIdentFind checks local members (including base classes) before global hash
tables. It preserves the hash mask, parent-table lookup and U32 use-counter
increments. It updates local_var_entry and returns a borrowed global record or
zero. Define-string records are returned unchanged: macro expansion and the
NO_DEFINES decision remain the dispatcher's responsibility. The production lexer
continues to use its original expansion and owned-string publication paths.

## Native contract and ownership

I386LexIdentScan takes an explicit heap for raw input, a control, the consumed first
character, caller-owned output storage/capacity, an output symbol pointer and a
line counter. It validates these arguments and the initial identifier domain,
normalizes initial script tokens, and rejects a literal at sign when KEEP_AT_SIGN
is set. Capacity must be at least two; callers implementing HolyC token dispatch
must use the language's STR_LEN limit. Smaller capacities are useful for bounded
component calls but do not redefine that language limit.

Success returns the length including NUL and resolves the symbol. -1 reports an
invalid/unsupported request or reader failure; -2 reports capacity exhaustion.
Failure can leave partial, unterminated output and consumed input. Lookup happens
only after a complete scan, so a read failure preserves local_var_entry and does
not increment lookup counters. The global output pointer is cleared on entry.

The adapter does not allocate an identifier string, set cur_str/cur_str_len/token,
expand a macro or perform the common final lookahead. The caller owns the output
buffer and must keep it live while used; symbol records remain borrowed. Raw input
may reclaim an owned include file as usual. Full token publication, macro expansion
and compiler-control destruction must account for their own allocations/lifetimes.
Stable, live symbol trees and exclusive compiler-control ownership are required.

## Retained runtime

CompilerRuntime interface version 4 adds ident_scan and is 28 bytes on i386.
The module imports HashFind and StrCmp from the kernel, so lookup uses its live
symbol table and shared comparison implementation. Member lookup runs in the
retained image. The kernel validates the fifth service pointer before publication.

Boot and task probes scan a copied I64i include into five bytes of caller-owned
storage, return to a cached parent semicolon with the child reclaimed, and resolve
exactly the registered I64i primitive record, check its eight-byte type width and
verify that scanning did not publish a token or allocate transient heap storage.
The verifier matches its exported function offset and rejects interface version 3.

## Verification

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-ident
python3 tools/test-i386.py --lex-punct
python3 tools/build-i386-kernel.py --test
```

The fixed scanner corpus first passed 276 cases against the original lexer at
4cf47e0: every length 1..143, all 128 extended bytes as initial and continuation
characters, script mappings, and both at-sign modes. Production Lex and a native
fixture using the scanner plus explicit publication/lookahead check the same text,
length, source position, lookahead, replay and buffer guards.

Lookup cases cover local/base-member precedence, parent hash tables, masks,
missing names, define records and U32 counter rollover. Failure cases cover every
read in short identifiers, capacity exhaustion before further lookahead, invalid
arguments, unsupported echo input, EOF, unchanged token/string ownership, and an
include transition rejected by a save point then explicitly restarted with full
reclamation. The fixture's token wrapper is test scaffolding, not a native lexer.

Complete dispatch and preprocessing, native parser/JIT integration, public runtime
ownership, DolDoc, native self-hosting and strict 386SX/DX verification remain open.

Identifier completion now has a separate native service combining this scanner
with shared finish dispatch and owned token/macro callbacks; see
[i386-lex-ident-token.md](i386-lex-ident-token.md). The scan-only API retains the
borrowed-buffer contract above.
