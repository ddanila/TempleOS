# Shared quoted-string decoding

`Compiler/LexString.HH/HC` supplies LexStringChunk, the quoted-string body decoder
shared by the production x86-64 LexInStr wrapper and the native raw-input adapter.
The shared implementation retains the existing simple escapes, embedded NUL,
zero/one/two-digit hexadecimal escapes, unknown-escape replay, dollar-count state,
and chunk boundaries. EOF retains the legacy terminating-NUL behavior even if no
closing quote was present. This is the decoder inside the lexer, not a complete
native token recognizer or a replacement shell.

The caller has already consumed the opening quote, sets CCF_IN_QUOTES where
required by its input service, and exclusively owns a live CCmpCtrl. CLexCharSource
holds a borrowed callback/context pair. The callback performs input transitions,
updates the control's last character, and honors CCF_USE_LAST_U16; the shared
helper owns escape decoding and puts lookahead back through that flag. Character
values used for bitmap lookup must be within the existing 512-bit token/character
domain. The callback and its context must remain live and return normally, or
unwind through the caller's established exception mechanism.

Each successful call returns the number of output bytes written. A completed
chunk sets done and includes its terminating NUL in that count; embedded NULs are
ordinary output bytes. An incomplete chunk leaves done false and has no added
terminator. At most size-1 bytes are written. Sizes zero and one return zero with
done false and consume nothing; callers need capacity of at least two to make
progress. Output and done storage must be writable and must not alias active
source/control state.

`I386LexStringChunk` connects this helper to I386LexRawChar through a stack-local
context containing the explicit heap and line counter. No new allocation is
needed for decoding itself, although the reader may release completed owned
input files. Native document, prompt and echo services retain their explicit
unsupported-mode failures. The native wrapper rejects missing control/counter/
done storage, negative sizes, and missing output storage when writes are possible.

A negative reader result produces -1 and done false. A failure can follow partial
output, input consumption and control changes; it does not roll back or preserve
the local escape parser for retry. The caller must abandon the operation or
explicitly restore/restart its input state. An ordinary incomplete successful
chunk, by contrast, is ready for the next decoding call.

## ToUpper prerequisite

The i386 backend now lowers IC_TOUPPER, with a standalone declaration in
Kernel/I386/String.HH. It changes only I64 values 'a' through 'z'. It preserves
other values, including wider and negative arguments, matching the existing
ICToUpper implementation despite the public U8 parameter spelling. Explicit U8
casts still use the ordinary language conversion rules. The same primitive is
used by shared hexadecimal escape decoding.

## Verification and integration

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-string
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

Both x86-64 rebuild/reboot generations and all three subsequent suites pass.
The separate string fixture uses numeric source/expected-byte arrays, so its
expected results do not depend on compiling escaped string literals with the
implementation under test. It covers 24 escape/dollar/EOF cases at capacities
2 through 8, all 256 hex bytes with both x/X prefixes and three chunk capacities,
320-byte strings, output guards, source positions, line counts and dollar state.
It also exercises 24 strings and a multi-chunk long string through the production
x86-64 Lex -> LexInStr -> LexStringChunk path.

Injected reader failures cover every read of representative plain, escape, hex
and dollar inputs. Native cases additionally reject unsupported modes and invalid
arguments, then decode an escape spanning a child/parent input boundary. A pending
save point first blocks the owned child pop; after explicit restart the same input
succeeds and reclaims the child record and buffer. ToUpper tests cover -512..1023,
selected wider I64 values, side effects and nested calls on both targets.

The adapter and decoder are compiled into the 340480-byte resident kernel, whose
complete 8 MiB QEMU/486 boot suite passes. Boot source consumption remains a raw
character pass: 14160 characters, 363 newlines, FNV32 0x52B06B53 and 14624 reclaimed
heap bytes. String decoding executes in the dedicated native fixture; boot does
not yet invoke a complete lexer. Native tokenization, macro/directive processing,
control lifecycle, document/prompt services, compiler/JIT execution, self-hosting
and strict 386 validation remain required.
