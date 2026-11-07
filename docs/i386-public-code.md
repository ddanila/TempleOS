# Public compiler graph services

`Compiler/PublicCodeCore.HC` shares the existing ICAdd, COCInit, COCPush,
COCPopNoFree, COCPop, COCAppend, COCMiscNew and COCDel bodies between PrsLib
and the native console. The extraction is byte-for-byte against the previous
PrsLib implementation; it retains the shared CodeCtrl graph operations and
symbol-release visitor. Native console version 242 adds eight function exports,
for 651 total bindings. Public controls and their graph allocations use the
existing system allocation services. Private frontend owner records remain
separate.

The contract checks nine independent properties: empty sentinels, instruction
metadata, trace/lock flags, miscellaneous-record initialization, nested restore,
non-freeing pop, append links, explicit release/reinitialization and borrowed
class preservation. The invalid address marker is compared as a pointer: its
stored value is 0x7FFFFFFFFFFFFFFF on the original and 0xFFFFFFFF on i386.
A first native run reached every check but returned mask 503 because the test
compared that pointer field against an uncast 64-bit integer. That result is
preserved in build/i386-code-control-native-v1; no implementation change was
needed for the pointer-width correction.

The pre-change image reaches normal startup and rejects the first COCInit
call (build/i386-code-control-baseline-v2). Initial original references could
not resolve these compiler internals from user scope; marking existing hash
bindings public and using an Adam job did not produce a completing reference.
Those attempts remain preserved under original-v1 through original-v3.
The source-copy reference instead extracts the exact relevant bodies from the
restored original PrsLib and compiles them before the unchanged contract. The
first corrected source-copy run passes mask 511 (original-v4). This is a
source-copy reference on the original system, not a shipped public-API test.

Both bootstrap generations and the full native cross-build pass. The terminal
cross-build source audit verifies all 1,756 delivered source hashes. The reusable
original-v5 and normal native-v2 contracts both pass mask 511, independently
audited against current inputs, exact original source prefix and frozen fixture,
and native fixture-only volume changes/boot bytes. The 8 MiB normal and 16 MiB diagnostic profiles each match all 307,200
welcome pixels; diagnostics complete both program/ownership/file-cleanup phases.
The source-loaded original token regression passes all 24 cases in
`build/i386-public-token-loader-v16`, with an independent original fixture,
result and unchanged Lex/LexExtStr body audit. See
`build/i386-public-code-memory-audit.json` for the memory-profile audit.

This supplies graph construction and ownership prerequisites, not expression
compilation or execution. Public LexExpression, PrsStreamBlk, normal-startup
full token delivery and C1–C5 qualification remain open. The contract does not
cover invalid graphs, allocation failure, every miscellaneous payload or
undefined-label diagnostics, and does not claim heap recovery from a memory
counter.
