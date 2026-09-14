# Native hash primitives

`Kernel/HashTypes.HH` is the shared declaration source for `CHash` and
`CHashTable`. `Kernel/KernelA.HH` includes it for x86-64; the native hash header
includes it for i386. Field order and fixed-width counters remain the same while
pointers follow the target ABI. The fixtures assert 24/32-byte record sizes on
x86-64 and 16/24-byte sizes on i386 respectively. `mask` and `locked_flags` remain
I64 on both targets; bucket slots are target-width pointers.

`Kernel/I386/Hash.HH/HC` implements the public `HashStr`, `HashBucketFind`,
`HashAdd`, `HashSingleTableFind` and `HashFind` interfaces in native HolyC.
Hashing retains the original assembly's 64-bit shift/add carry and final
shift/add fold. It does not truncate the hash to the pointer width. A null
string hashes to zero, as on x86-64; searches compare complete, case-sensitive,
zero-terminated byte strings through native public `StrCmp`. Its unsigned byte
ordering and exact -1/0/1 result also support shared compiler member lookup;
see `i386-symbols.md`.

Lookup applies the type mask, searches newest insertions first, carries the
requested match instance across parent tables, and increments only the selected
entry's U32 use counter, including rollover. That increment is interrupt-masked
so a nested lookup cannot lose a count between its load and store. Nonpositive instances do not match.
`HashAdd` preserves caller IF while publishing the new bucket head in an
interrupt-masked section. These routines allocate no memory. They require live
caller-owned strings, entries and table storage, power-of-two bucket counts with
`mask=count-1`, and acyclic chains. A caller must keep searched chains stable;
there is no NMI or multicore synchronization guarantee in this single-CPU path.

The standalone kernel uses these routines for its resident loader export index.
Its private records now extend the shared `CHashExport` record with a module-binding
kind. Startup obtains the three required bindings by name through `HashFind`,
reads each I64 value through shared `HashVal`, checks it fits a 32-bit address,
then uses the checked disk module loader. These are export records, not substitutes
for compiler `CHashFun`/class/variable records. See `i386-symbols.md`.

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --hash
python3 tools/build-i386-kernel.py --test
```

The hash fixture captures 512 results from the actual x86-64 `HashStr`, including
empty strings, high-bit bytes, long strings and carry/overflow cases, and compares
them in the native runner. Its deterministic byte generator explicitly masks
wide intermediates so both compiler targets produce identical strings. Additional
cases cover forced collisions, type filtering, duplicate instances, parent-table
lookup, case sensitivity, use-counter rollover, insertion order, caller IF and
four-byte bucket addressing. Exported oracle/module data and an executable-region
instruction audit accompany the fixture.

Construction/destruction of rich compiler symbol records, task symbol-table
ownership, compiler initialization and native source compilation remain pending.
The implementation does not change the x86-64 assembly primitives. The full
standalone/self-hosting and strict 386 verification requirements still apply.

## Heap-owned table lifetime

`HashTable.HH/HC` adds explicit-heap native interfaces:

- `I386HashTableNew(heap,buckets)` allocates an owner record and zeroed bucket
  array. Bucket counts must be positive powers of two whose target-width array
  size fits in U32. Failure returns zero and releases any unexposed allocation.
- `I386HashTableValid(heap,table)` checks allocation extents, the private owner,
  bucket count and array size before trusting the record. It does not validate
  every entry, string or chain; callers own those lifetimes and invariants.
- `I386HashTableResize(heap,table,buckets)` preserves the table address, entries,
  parent link, use counters and equal-name instance order. It allocates the new
  buckets before relinking; allocation failure leaves the live table unchanged.
  It reverses each old chain and then prepends entries into the new buckets,
  avoiding a second temporary tail array. Cached bucket/link pointers become
  invalid after a successful resize; pointers to the entries remain valid.
- `I386HashTableRemove(heap,table,entry)` detaches the exact entry identity and
  clears its next pointer. It does not free that entry or its string, and does
  not search a parent table.
- `I386HashTableDelete(heap,table)` requires an empty, unlocked table and frees
  both owned allocations. It does not free the parent table. The caller must
  detach incoming references and finish all uses before deletion.

All operations preserve IF and serialize heap/table changes on the single CPU.
Resizing, removal and deletion reject a nonzero `locked_flags`. Tables, entries
and names must be live and disjoint, chains acyclic, and indexed names immutable.
The public record's owned body/mask must be changed through these interfaces.
No callback or yielding occurs during relinking. A heap-corruption failure after
relinking is not a rollback guarantee; the unchanged-table guarantee concerns
rejected requests and failed allocation before mutation. Historical heap peak
accounting can increase during a failed creation attempt even though all its live
allocations are reclaimed.

The standalone export index now uses `I386HashTableNew` and keeps its three
resident entries separately. The expanded `--hash` fixture checks partial-creation
failure, exhausted-heap resize, growth/shrink cycles, duplicate-order and counter
preservation, locked/nonempty rejection, exact removal, parent survival, wrong
heap/interior-pointer rejection, IF preservation and full arena reclamation.
Its 128 KiB test stage remains below the private test heaps. Standalone startup,
keyboard/VGA checks and both x86-64 rebuild/reboot generations also pass.

These explicit-heap APIs support the native compiler integration; they do not
implement the public `HashTableNew(size,mem_task)` task-selection contract or
typed `HashDel` destruction of compiler symbol metadata. Those integrations
remain required work.
