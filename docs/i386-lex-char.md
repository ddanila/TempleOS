# Shared character-constant parsing

The production x86-64 lexer and native I386LexChar share LexCharBody. The body
starts after the opening quote and packs up to eight decoded bytes into an I64,
retaining the original escape, hexadecimal and dollar rules. This includes empty
constants, embedded zero bytes, unknown-backslash replay, zero/one/two-digit hex
escapes and EOF as an implicit terminator. Character constants do not modify the
string decoder's dollar counter. The x86-64 dispatch still honors CCF_NO_CHAR_CONST
and raises the existing diagnostic for a ninth decoded byte.

The shared reader owns input/replay and include transitions. LexCharBody returns
TK_CHAR_CONST on success, -1 for a negative reader result, or -2 when the closing
check encounters another character after eight decoded bytes. It publishes the
value and token only on success. Error returns can leave input, line and replay
state partially consumed; they do not promise rollback or resumable escape state.
The body expects live control/source records and a valid character-reader domain,
like the existing string and numeric bodies.

I386LexChar validates the control and line-counter arguments and rejects
CCF_NO_CHAR_CONST. It uses I386LexSourceRead and performs the original common final
lookahead, setting replay on success. A failure during that final lookahead returns
-1 with the already decoded value/token still published. Callers must use the
return status. Unsupported prompt/document/echo modes remain errors in the native
raw reader. Full native token dispatch and those input services remain unfinished.

CompilerRuntime interface version 2 introduced char_token in a 20-byte interface.
Version 3 retains it alongside the added punctuation service. The
kernel validates and retains this third code pointer alongside string/number
services. Boot and task probes parse a hexadecimal escape followed by a literal
byte into 0x4241, checking source position, final lookahead and heap accounting.
The boot verifier matches all three service addresses to exported function offsets
and rejects the old interface version before publishing services.

## Verification

Run the existing fixtures:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-string
python3 tools/build-i386-kernel.py --test
```

The string fixture now includes 536 character cases: lengths zero through eight,
all 256 hexadecimal bytes with both prefix cases, simple/unknown escapes, dollar
handling, raw newline and shortened hex escapes. Fixed expected values and source
positions first passed against the original x86-64 lexer at 723d506, before the
extraction. The same cases exercise production Lex after extraction and native
I386LexChar. Existing string and ToUpper checks remain in this fixture.

Injected reader failures cover every read through hexadecimal and dollar paths,
as well as the closing check after eight bytes. Overlength and body failures must
leave token/value sentinels unchanged. Native cases cover invalid arguments,
disabled character constants, unsupported prompt input, EOF, an escape crossing an
owned include boundary, save-point rejection followed by explicit restart and
reclamation, and a final-lookahead failure after successful body decoding.

These checks establish a shared lexer component and execution through a retained
native service. They do not establish full tokenization, preprocessing, a native
compiler/JIT, strict 386SX/DX support or self-hosting.
