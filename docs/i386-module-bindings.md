# Resident i386 module bindings

`Kernel/I386/ModuleBind.HH` defines an explicit resident symbol table. Each
`CI386ModuleBinding` has a live name pointer, a kind (function export 1 or data
export 3), and a nonzero 32-bit address. Names are 1–255 bytes. Addresses must
refer to compatible live native code/data; this table does not validate memory
ownership, function signatures or the contents of an arbitrary address.

`I386LoadBoundInto` adds that table to the existing module-set loader. The entry
point must still be a unique function exported by the input modules. Imports can
resolve to a module export or a resident binding, but ambiguity is rejected:
duplicate table names and table/module name collisions do not override one
another. Direct-call relocations require function bindings. Address relocations
retain the existing module-format convention of accepting code or data addresses.

Module-only targets use image-relative offsets. Resident addresses are converted
to offsets from the final image address, then patched as 32-bit relative values.
The same size query and validate-before-write contract applies. Bound output must
fit the 32-bit address space. Output overlap with binding records/names or a
resident target's starting address is rejected, in addition to existing module,
size-table and entry-name overlap checks. The caller must independently ensure
the whole resident code/data regions stay live and do not overlap output storage.

`I386LoadBoundAlloc` adds heap allocation and cleanup. `I386RedSeaLoadBound` and
`I386RedSeaLoadSetBound` add the same binding table to disk file loading. Existing
unbound APIs retain their signatures and behavior. Tables and names are consumed
during loading and can be retired afterward; resident targets must outlive all
loaded images using them. There is no automatic kernel export discovery, provider
pinning, symbol registry or unload dependency tracking yet.

`python3 tools/test-i386.py --redsea-bind` loads a consumer file importing a
function and mutable 64-bit data. Native resident code services the call; changes
to the resident data are visible to the loaded module. Clearing the binding
addresses after loading does not affect execution. The fixture covers single-file
and one-file set entry points, provider/table collisions, missing/duplicate/wrong-
kind/invalid bindings, long names, overlapping output and high-address relocation
arithmetic. Rejected direct loads preserve sentinel output. The synthetic high
address is checked as a relocation value and never executed.

The existing shared-loader corpus is rerun for unbound behavior. These are native
runner checks, not a production kernel export table or a completed boot/JIT path.

The binding consumer also redeclares a previously extern function as an import.
PrsFunJoin may consume/free the incoming name while retaining the existing symbol;
the import branch now copies that symbol's owned name. This fixes malformed direct
call import names exposed by the retained compiler runtime. The expanded binding
fixture and both x86-64 rebuild generations pass. See
[i386-compiler-runtime.md](i386-compiler-runtime.md) for the boot lifetime contract.
