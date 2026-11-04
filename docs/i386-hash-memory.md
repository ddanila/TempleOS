# Hash memory accounting

LinkedLstSize, MemberLstSize, HashEntrySize2 and HashTableSize2 now retain their
complete original bodies through three shared units. Original KDataTypes,
LexLib and CHash include them in place. Console ABI 209 has 582 bindings and
publishes LinkedLstSize, HashEntrySize2 and HashTableSize2 through public headers;
member accounting remains their internal recursive dependency.

Every original branch is present: source links/index/import names and opaque
import nodes; export debug records; class members, dimensions, defaults,
metadata and function pointers; function debug-code extents; global dimensions,
aliases, data and normalized function-pointer descriptors; embedded dictionary
names; file and module payloads. Original exclusions are preserved, including
kernel-module payloads, alias data, embedded dictionary strings, define sub_idx
and a table's parent chain. Debug-code extent contributes its original logical
byte span. This is the original accounting rule, not a generic reachability sum.

The paired fixture constructs owned standard metadata records and records each
allocation's actual MSize2 at construction time. Its expected ledger includes
known ownership exclusions and a controlled 37-byte debug-code extent. It does
not walk fields to reproduce the implementation's traversal. Eighteen cases
pass result/value equality and exact caller-heap recovery on both rebuilt
original and native systems:
`build/i386-hash-memory-reference-v1/result.json` and
`build/i386-hash-memory-native-v1/result.json`, with unchanged inputs.

The native run uses 64 MiB, real WinMgr, exact framebuffer checkpoints and a
resumed arithmetic command. Two original rebuild generations pass
(`build/hash-memory-rebuild-v1.log`); the cross-build passes the 386 audit and
all 1,260 packaged candidate source/documentation files match independently
(`build/i386-hash-memory-cross-v1/source-audit.json`). Shared bodies match the
preceding original implementations apart from trailing blank lines.

The unchanged MakeAC source now loads successfully against real native services
and a subsequent command executes
(`build/i386-hash-memory-autocomplete-v1/result.json`). No throwing stream or
other replacement services are supplied. Source loading alone does not qualify
initialization, actual dictionary records, autocomplete task behavior or visible
suggestions.

Borrowed native bootstrap/compiler tables use a different allocation convention
from the public MSize2 allocator and are outside this qualification. These tests
cover owned standard records; whole native task/root-table accounting, corrupted
graphs, concurrent mutation, full memory reporting, 8 MiB resource gates and
C1-C5 remain open. They must be resolved separately rather than routing unknown
records through a generic-entry-only implementation.
