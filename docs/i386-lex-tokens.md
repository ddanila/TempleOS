# Native token dispatch

`Compiler/I386/Lex.HC` connects the existing native token handlers through
`I386LexNext(heap, cc, tables, macro_filename, compiled_lines)`. The caller supplies
initialized punctuation tables, a live compiler control/input stack and the heap
that owns token text and included sources. This is a frontend integration step;
preprocessing directives, prompt/document input and the parser/JIT remain open.

The dispatcher handles whitespace, identifiers and string-macro expansion,
number/dot tokens, owned string tokens, packed character constants, punctuation,
comments, literal-at/hash/newline flags and inserted-binary token replay. Macro
expansion resumes dispatch internally, so replacement text can contain different
token kinds. It captures `last_line_num` at entry and retains each handler's final
lookahead and replay behavior. EOF returns `TK_EOF`.

Negative results are explicit and must be checked before entering the parser:

| Result | Meaning |
| --- | --- |
| -1 | Invalid service/input state or a reader/allocation failure |
| -3 | Identifier exceeds the existing STR_LEN bound |
| -4 | A preprocessing directive is encountered without KEEP_SIGN_NUM |
| -5 | Character constant exceeds eight packed bytes |

Errors do not rewind consumed input. Handler-specific publication and ownership
rules still apply, including published tokens when final lookahead fails. The
caller eventually releases `cc.cur_str` and owned input/control records; successful
non-text tokens do not discard the preceding text allocation. No error here is
silently converted to EOF or a successful token. Directive handling must be added
before this can consume general HolyC source.

`python3 tools/test-i386.py --lex-tokens` runs shared mixed-stream expectations
through actual x86-64 `Lex` and the native dispatcher. It exercises a wide integer,
an exact binary64 literal, embedded-NUL strings, packed characters, nested comments,
compound operators, macro chains/empty expansion/shadowing, token flags and line
metadata. Native cases check directive and length errors, unavailable prompt input,
inserted-token replay, invalid cached input and allocation failure retaining the
previous owned text/token. The native fixture checks complete
heap reclamation. The larger runner reserves a 256 KiB stage and places its test
heap at 0x60000; CR0.EM is enabled. This QEMU/486 fixture is not strict 386 or native
shell validation. Fractional-literal numerical-policy differences remain governed
by the separate numeric-token corpus and architecture plan.

The mixed-macro case expands one identifier into both an F64 token and a string,
then resumes the parent delimiter. The runner reports one aggregate Main result;
it is not a claim of only one token assertion. Both the expanded mixed fixture
and the existing 1,089-case numeric corpus pass with the shared large-stage guard.
The x86-64 rebuild regression also passes both generations.
