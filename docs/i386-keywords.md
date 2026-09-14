# Native compiler keyword registry

`I386KeywordsInit` creates an owned hash table containing the existing 48 language
keywords and 25 assembler keywords. Entries retain their exact names, keyword
numbers and HTT_KEYWORD/HTT_ASM_KEYWORD types. Each CHashGeneric and its name are
separate owned allocations. The registry supplies symbol recognition; recognizing
USE64, for example, does not enable 64-bit code generation on the i386 target.

Compiler/Keywords.HH now shares both language and assembler keyword constants.
Compiler/KeywordTable.HC contains bootstrap descriptors generated from the KEYWORD
and ASM_KEYWORD records in OpCodes.DD. `tools/gen-compiler-keywords.py --check`
verifies the complete inventory, names, values, constants and generated file. The
native-kernel build and keyword fixture run that check. The existing x64 assembler
continues to read OpCodes.DD normally; the fixture compares every descriptor with
its actual initialized hash table, including type-specific lookup and duplicates.

The generated HolyC table is shipped source and requires no Python in the guest.
When changing the opcode-source keyword inventory, regenerate/check it on the
bootstrap host. This table bootstraps native keyword lookup; the full native
opcode/register table loader and its source-driven initialization remain separate
work, alongside the unfinished parser and assembler integration.

The caller supplies a zeroed, exclusively owned CI386Keywords registry. Failed
initialization reclaims partial entries, names, buckets and owner records and
clears the registry for reuse. Keep its membership and payloads stable after
publication; ordinary lookup may update use counters. Definitions belong in a
higher table. Detach incoming table/symbol references before deletion, which uses
the existing table-removal and symbol-destructor paths. A locked table is rejected
without destroying the registry. Initialization and destruction are not concurrent
operations; allocation and hash primitives preserve their short IF-masked updates.

The boot kernel retains the registry for its lifetime, with this lookup chain:

`resident symbols -> primitive types -> keywords`

Primitive F64 therefore precedes the assembler keyword of the same name. The
CompilerProbe definition test no longer supplies a synthetic define keyword: its
local definition table inherits the real registry through resident symbols, both
at boot and after task/timer activity. The probe module is still reclaimed after
its second call; the keyword registry remains live.

Run:

```sh
python3 tools/gen-compiler-keywords.py --check
python3 tools/test-rebuild.py
python3 tools/test-i386.py --keywords
python3 tools/build-i386-kernel.py --test
```

All checks pass. The keyword fixture verifies all 73 mappings against x64 and
natively, exact owned allocation sizes, case/type masks, parent shadowing, rejected
reinitialization, locked deletion, reuse and cleanup across 1021 heap arenas from
32 to 8192 bytes. The runner reports one aggregate Main result with these checks.
The registry retains 6208 bytes in 148 allocations: 48 bytes for the table owner,
272 for buckets, and one 56-byte record span plus each aligned name span per entry.

Both x64 rebuild/reboot generations and the full kernel boot/VGA/keyboard/timer/
rejection suite pass. The bootstrap is 372288 bytes, leaving 20928 bytes in its
unchanged reservation. These are 8 MiB QEMU/486 development results; complete
preprocessing, public compiler-control APIs, parser/JIT, DolDoc, native self-hosting
and strict 386 validation remain required.
