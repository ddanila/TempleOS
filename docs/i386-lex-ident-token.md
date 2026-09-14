# Native identifier tokens and string-macro expansion

LexIdentFinish now shares the production decision between expanding a string
macro and publishing an identifier. The x86-64 callbacks retain the existing
LexIncludeStr, StrNew/Free, token-field and exception behavior. STR_LEN remains
144 and now has one shared definition in Kernel/StringLimits.HH.

I386LexIdentToken combines the shared scanner/lookup with native finish callbacks.
It returns TK_IDENT after publishing a heap-owned cur_str, setting cur_str_len,
hash_entry and token, and performing the common final lookahead. It returns -2
after copying an enabled string macro into a define-marked input child; the caller
must resume token dispatch. -3 reports an overlength identifier and -1 reports a
reader, argument, allocation or publication failure. The first character is
already consumed, as with the existing component adapters.

The caller supplies the macro diagnostic filename; expansion requires that name
and the definition's live NUL-terminated data. NO_DEFINES suppresses expansion.
Local members continue to shadow global macros through the shared lookup. Empty
and chained string macros use the same owned include/parent-replay machinery.
This helper does not parse #define directives or dispatch the resulting numeric,
string or punctuation tokens; those are full-lexer integration work.

## Ownership and failure

Published cur_str uniquely owns its allocation in the supplied heap; it must not
alias active file buffers or other independently owned storage. Replacing it checks that the old
pointer is an allocation in that heap, allocates/copies the replacement, then
frees the old allocation and publishes fields. A failed allocation preserves
cur_str, cur_str_len, hash_entry and token. Input consumption, local_var_entry and
lookup use counts are not rolled back. A caller must honor the returned status
and arrange compiler-control recovery/destruction.

Expansion keeps the previous owned token text until a later token is published.
The include owns independent name/source/record allocations, reclaimed on normal
EOF return. Failed include preparation preserves the active input stack after
scanning. Pending save points retain their existing pop restriction; general
lookahead across includes remains unfinished. The eventual control destructor
must free the last published string as well as drain source/snapshot ownership.

Heap allocation/free and field publication preserve IF using short masked
sections. The bounded string copy occurs with the caller's IF restored. All
controls, symbol records and borrowed input buffers must remain live and
exclusively owned according to the existing reader/lookup contracts.

## Retained service and tests

CompilerRuntime interface version 5 adds ident_token and is 32 bytes on i386.
The module imports the kernel's explicit heap, IRQ save/restore and owned-include
functions. Headers precede those explicit imports. The kernel validates the sixth
retained service address and rejects version 4 before publication.

Boot and task probes resolve a Type macro to the live I64i primitive through two
service calls. They check the expansion outcome and its three allocations, the
published identifier and single remaining string allocation, then release that
string and verify the original heap baseline. The verifier requires both IDENT
PROBE records and matches the exported service address.

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-ident
python3 tools/test-i386.py --lex-punct
python3 tools/build-i386-kernel.py --test
```

The 276 identifier cases now use the actual native token service and verify its
allocation size before copying/freeing the output for comparison with production
Lex. Shared host/native cases cover chained macros, NO_DEFINES, empty expansion,
local-variable shadowing, use counts and parent input recovery. Native cases also
check preservation of an old owned token during expansion and normal/macro
allocation failure, replacement/reclamation, and overlength before publication.

Complete lexical dispatch, macro/directive creation and general include lookahead,
native parser/JIT, public runtime ownership, DolDoc, self-hosting and strict 386
validation remain required.
