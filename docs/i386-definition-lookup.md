# Native list and definition lookup

ConsoleRuntime 19 retains the original `LstSub`, `LstMatch`, `Define`,
`DefineSub`, `DefineCnt` and `DefineMatch` bodies. They are shared through
`Kernel/ListCore.HC` and `Kernel/DefineLookupCore.HC`; extraction leaves the
original x64 bodies byte for byte unchanged. Public declarations are in
`Kernel/I386/PublicHash.HH`. The list-match flags now have one shared header.

These are dependencies of original formatting and document selection, not a
complete formatting provider. `StrPrintJoin` uses raw/defined strings and list
substitution through these interfaces. Full general formatting, document layout,
editor callbacks and the edit/save/reboot/reopen workflow remain unfinished.

Lookup borrows the definition's owned string/index storage. It searches the
current task's hash table chain, preserves local shadowing, and returns null
for out-of-range list ordinals. Null definition names preserve the original
null/-1 return values. Missing non-null names report the literal name and throw
`UndefDef`. On native i386 the existing literal console boundary prints the
error without allocating, interpreting formatting characters in the name, or
changing the caller's interrupt/display/filter state. Colored DolDoc diagnostic
output awaits the full terminal integration.

List matching preserves aliases, exact-match precedence, optional case folding,
-1 for no match and -2 for ambiguity. It retains the original behavior even when
multiple prefix matches happen to refer to one aliased ordinal. This port does
not substitute host-language matching semantics.

## Verification

A shared 16-case corpus checks list ordinals, alias matching, ambiguous prefixes,
exact matching, case folding, null/empty lists, inherited definitions, local
shadowing, scalar-definition counts and the live `ST_COLORS` list. Temporary
parent/child hash tables are detached and destroyed after restoring the current
task's original table. The native command wrapper additionally requires exact
heap reclamation across the entire corpus.

Four missing-definition checks cover each lookup entry point. Both x64 and i386
must catch `UndefDef`; native calls also require unchanged heap usage and exact
visible diagnostics with a name containing `%s`. The x64 diagnostic appends to
its DolDoc terminal, so it is deliberately not subject to the native
allocation-free reporting assertion.

## Validated result and cost

Both x64 rebuild/reboot generations and the full QEMU/486 8 MiB native suite
pass. The interactive suite passes 198 commands / 261 input lines, including
16 lookup groups, four missing-definition cases, exact heap reclamation, four
VGA frames and 11 hardware breaks. Startup recovery and all 17 module rejection
checks pass. All 1150 source hashes, 12 build-input hashes and both disk hashes
match. The normal preview was refreshed from the verified image.

Normal boot measured 23.029 seconds; separate diagnostics took 135.367 seconds.
ConsoleRuntime 19 retains 187672 bytes (187656-byte image), an increase of 6320
bytes over version 18. Service/configuration records remain 32/32 bytes. The
kernel is 365016 bytes, leaving 24104 bytes of reserved-load headroom. These
results are QEMU/486 evidence; strict 386 and physical-PC acceptance remain open.
