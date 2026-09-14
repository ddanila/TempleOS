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
zero-terminated byte strings.

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
Its private records extend the shared `CHash` prefix with a module-binding kind
and 32-bit address. Startup obtains the three required bindings by name through
`HashFind`, then uses the checked disk module loader. These private records are
not substitutes for compiler `CHashFun`/class/variable records and must not be
inserted into a compiler symbol table as such.

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

Table allocation/destruction, rich compiler symbol records, task symbol-table
ownership, compiler initialization and native source compilation remain pending.
The implementation does not change the x86-64 assembly primitives. The full
standalone/self-hosting and strict 386 verification requirements still apply.
