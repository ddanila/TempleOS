# Public linked-list copying and deletion

Normal startup now publishes LinkedLstCopy and LinkedLstDel with the original
signatures. LinkedLstCopy preserves each node allocation and payload, rebuilding
next links into independent copied storage; its optional task/heap selector is
passed unchanged to MAllocIdent. LinkedLstDel frees every node in a valid acyclic
list. Null lists are accepted by both functions.

Kernel/LinkedLstCopyDelCore.HC is the exact original KDataTypes.HC prefix, shared
by the original kernel and native console. Console version 245 appends function
bindings 653/654 without changing data-export bits or existing bindings. The
strict builder requires both actual functions. The source-loaded compiler probe
now uses this delivered deletion function for array-dimension cleanup, without
injecting a test copy.

Run tools/test-i386-linked-list.py --out OUT for the actual original, or supply
a native image before --out. Both original-v2 and native-v1 pass mask 1023:
null copy/deletion, four varied allocations and copied links, exact payloads and
allocation sizes, independent mutation, deletion recovery, explicit current-task
copy, full source release and a singleton. Payload comparisons exclude only next
pointers, whose widths differ between architectures. Result buffers remain alive
until guest shutdown. The old image fails at the first missing LinkedLstCopy
call (baseline-v2, line 9).

Independent audits check exact original shared bodies, current inputs and fixture,
normal startup, fixture-only native volume changes and unchanged boot bytes.
Both x86-64 bootstrap generations rebuild and boot with stable source pins; this
is not binary reproducibility or C5 native-generation qualification. The full
native build passes 1758 source pins and 386 instruction auditing. The first
cross-build failure used NULL before its early prototype scope defined that macro;
the fixed prototype uses zero and both bootstraps were rerun. Initial fixture
attempts used a local aggregate initializer; that baseline failed before the API
call, so sizes now use a global array. The first reference was deliberately
stopped and is not acceptance evidence.

The source-loaded expression integration now passes all nineteen stages, 24 token
cases, graph mask 63, nine basic executions, six type checks and eleven runtime
cases with exact original executable records. Its 1027-input audit confirms no
test deletion body is supplied: dimension cleanup uses the normal binding. Both
8/16 MiB profiles match all 307200 welcome pixels with normal startup. Both
diagnostic program, ownership and file-cleanup phases pass.
Other-task/heap selection, allocation failure, cyclic/invalid lists, other data-type
APIs and full compiler/C1–C5 qualification remain open.

Evidence: build/i386-linked-list-original-v2, build/i386-linked-list-baseline-v2,
build/i386-linked-list-native-v1, build/i386-linked-list-cross-v2 and
build/i386-linked-list-source-body-audit.json.
