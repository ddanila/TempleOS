# Owned native string tokens

I386LexStringToken constructs a complete string token after the opening quote has
been consumed. It uses the shared LexStringChunk decoder at STR_LEN capacity,
appends by explicit byte count and publishes the completed buffer directly as
cur_str. Embedded zero bytes are retained; cur_str_len includes the final NUL and
the allocation's requested size equals that length. The x86-64 lexer is unchanged.

The current builder grows by decoded chunks, allocating/copying a larger temporary
buffer and then releasing the old temporary. This keeps the existing token text
live until the full replacement is ready. It does not add a new length restriction
below the native allocator's checked size limit. Long-string construction still
needs performance/peak-memory measurement in the complete low-memory workflow.

## Ownership and errors

The previous cur_str must uniquely own an allocation in the supplied heap, with
no alias to independently owned source buffers. On allocation or body-reader
failure, temporary builder storage is reclaimed and the previous cur_str,
cur_str_len and token remain unchanged. The original hash/member associations
also remain untouched. Consumed input, include transitions, dollar/line counters
and replay are not rolled back. IN_QUOTES remains set after a body failure that
started decoding; retry requires an explicit input restart or compiler recovery.

Successful publication releases the previous text, sets TK_STR and the new length,
and clears IN_QUOTES before common final lookahead. If that lookahead fails, -1
is returned with the completed string already published and owned by the control.
The caller must check the return status and arrange cleanup. Successful completion
sets replay and returns TK_STR. Heap operations preserve IF; buffer copies run
outside the masked sections. The caller owns the control and input exclusively.

## Retained runtime and verification

CompilerRuntime interface version 6 adds string_token and is 36 bytes on i386.
It uses the existing imported heap/IRQ providers. The kernel validates the seventh
service address and rejects version 5 before publication.

Boot/task probes first produce an owned identifier from a macro, then replace it
through the string service with the four bytes a, zero, b, zero. They verify the
exact allocation size, retained symbol association, delimiter and allocation
count, then free the string and check the original heap baseline. Both STRING
PROBE records and the exported service address are checked by the host verifier.

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-string
python3 tools/test-i386.py --lex-ident
python3 tools/build-i386-kernel.py --test
```

Host/native tests cover 24 existing escape/EOF/dollar cases, ten lengths spanning
chunk boundaries through 2048 bytes, and adjacent strings retaining dollar state
while replacing owned text. Native allocation tests span 253 arena sizes from
32 to 2048 bytes, preserving old text and reclaiming temporary builders on failure.
Include tests fail after an allocated partial chunk, explicitly restart and reclaim
the child, and check a final-lookahead failure after token publication. Existing
string/character/identifier cases remain regression coverage.

Full lexical dispatch, directives and general include lookahead, native parser/JIT,
public runtime destruction, DolDoc, native self-hosting and strict 386 validation
remain required.
