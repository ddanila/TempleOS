# Native HashAddAfter

Kernel/I386/HashAddAfter.HC ports the original _HASH_ADD_AFTER assembly policy:
save interrupt state, disable local interrupts, read pred->next, write entry->next,
write pred->next, and restore the saved state. The table parameter remains part
of the original signature; insertion does not recompute a bucket or change table
flags. A bucket-head pointer can serve as the predecessor because next is the
first CHash field. Records and their payloads remain caller-owned.

Console version 243 adds _HASH_ADD_AFTER as function slot 651, bringing the
binding count to 652. PublicHash.HH supplies the original API signature. The
implementation uses existing native IRQ save/restore services and pointer width;
it does not bind a private compiler control to the public ABI.

The actual original contract passes mask 255 in
build/i386-hash-add-after-original-v1. The pre-change normal image reaches
startup and rejects the first HashAddAfter call at line 12 in baseline-v1.
The revised normal image passes mask 255 in native-v1. The contract checks
middle/tail/head insertion, untouched payloads, duplicate-name lookup order,
IF preservation from both disabled and enabled states, and ordinary data-heap
recovery after deleting the valid table. The exported result allocation is
retained until shutdown and is allocated after the heap-recovery observation.

Independent audits verify the restored original source and exact fixture,
recorded input pins, exact native/reference result, fixture-only native volume
changes and unchanged boot bytes. Original/baseline builder pins refer to
revision 9cb7bbca; they predate the console-version change. Both bootstrap
generations and the source-pinned native build pass. Both 8/16 MiB profiles
match all 307,200 welcome pixels; diagnostics complete both program/ownership/
file-cleanup phases (build/i386-hash-add-after-memory-audit.json). Full unchanged
expression-parser publication passes this binding and reaches missing Call at
PrsExp line 173 in build/i386-public-expression-loader-v4.

The contract covers valid exclusive acyclic chains. Predecessor membership,
invalid graphs and multiprocessor exclusion are outside its coverage.
Full expression compilation, stream blocks and C1–C5 qualification remain open.
