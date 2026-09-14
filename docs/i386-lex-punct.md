# Shared operator and comment parsing

LexPunctInit populates the three existing packed U32 token tables from one shared
initializer. The x86-64 compiler retains its zero-allocated writable tables and
public cmp pointers. Native callers supply three zeroed TK_TKS_NUM arrays and a
CLexPunctTables record; the initializer retains no addresses.

LexPunctBody starts after the first punctuation character. It preserves table
lookup order, doubled operators, shift assignments, nested block comments, line
comments, dollar-delimited text and literal-dollar handling. The reader supplies
characters and owns replay, line accounting and include transitions. Line comments
continue to consult the shared writable char_bmp_non_eol bitmap.

The return is a token (including zero for EOF), -1 for a reader failure, or -2 when
a comment/document marker has been skipped and dispatch must resume. On a token,
finish tells the caller whether to perform the common final lookahead. EOF inside
a block comment returns immediately without that lookahead or setting replay;
this is distinct from EOF inside skipped dollar text. KEEP_NEW_LINES preserves
the original line-comment behavior, including a newline token at end of input.

I386LexPunct validates pointers and the supported initial punctuation domain,
provides the native raw reader, and performs final lookahead when requested.
It propagates -1/-2. A final-lookahead failure can occur after token publication;
callers must handle the returned status. Errors do not roll back consumed input,
include changes or replay state. The shared body requires live records/tables and
a valid reader, matching the other shared lexer components.

The dedicated --lex-punct fixture exercises punctuation-only dispatch; it is not
a general native lexer. Fixed expected tokens, cursor positions, final characters,
replay flags and line counts first passed 78 cases against the original lexer at
afae6fb. Cases cover all 23 compound operators, individual punctuation, unmatched
lookahead, nested/repeated comment delimiters, dollar forms, EOF and newline
retention. The same corpus is used for the shared production and native paths.
Injected reader failures, mutable tables and an include transition in the middle
of a nested-comment delimiter test error state and reclamation. Native cases also
check failure after token publication and a changed shared line-ending bitmap.

Full lexical dispatch, identifiers/macros/directives, document/prompt services,
native parser/JIT integration and self-hosting remain required. Instruction audits
and QEMU/486 tests do not establish strict 386SX/DX support.

## Retained service

CompilerRuntime interface version 3 adds punct_token and is 24 bytes on i386.
The module owns its three writable token tables and initializes them through the
same LexPunctInit used by x86-64. It imports the kernel's actual char_bmp_non_eol
array, preserving the shared classification storage. No additional heap allocation
is needed for these tables: they live with the retained module image.

The kernel validates the fourth service pointer before publication. Boot and task
probes skip a line comment through that service, resume source reading and parse a
shift-assignment token. They check line accounting, lookahead and unchanged heap
usage. The verifier checks its exported address and rejects interface version 2.

Run:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-punct
python3 tools/test-i386.py --lex-string
python3 tools/build-i386-kernel.py --test
```
