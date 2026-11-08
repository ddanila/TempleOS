# Deferred assembler resolution: original baseline

`tools/test-i386-asm-resolve.py` boots the pinned original OS and compiles the
complete original `Compiler/AsmResolve.HC` under private reference names. It also
loads the original non-public `AOTStoreCodeU8At` implementation needed by that
module. Both sources come from revision
`c26482bb6ad3f80106d28504ec5db3c6a360732c`; the runner records their combined hash,
restored OS hashes, fixture, runner, and harness input hashes.

The fixture executes allocated x86-64 expression thunks through `Call`. Each
increments an initialized counter before returning its constant. This checks that
construction defers execution and resolution executes each expression once.
There is an i386 thunk encoding in the fixture for subsequent native delivery;
this baseline does not qualify that encoding.

The 32 assertions cover:

- All eight signed-relative/immediate widths, truncated bytes and adjacent guards.
- A two-byte immediate crossing the 64 KiB AOT block boundary and the resulting
  length, while indexed stores leave the current assembly position unchanged.
- Undefined-expression addends and relocation type/site/packet ownership.
- Local precedence when both local and global reference lists are provided,
  constructor fields, LIFO insertion, local patching, list consumption, and a fresh
  local hash table chained to the global table.
- Two uses of an imported symbol: copied constructor names, immediate flags,
  metadata order, external alias naming, packet identity, and retained addends.
- A defined function's external call patch and exported name/type/address.

Original behavior is recorded explicitly: global resolution leaves its consumed
unresolved-list head and function external-usage head stale. It also retains the
constructor's duplicated import names. The fixture observes those pointer values
without dereferencing freed records, clears the heads, and frees the retained
names. A future shared/native implementation must specify and verify its repaired
ownership separately; an original pass does not prove native ownership.

Verified capture:

```
python3 tools/test-i386-asm-resolve.py --out build/i386-asm-resolve-original-v6
```

The result passes all 32 assertions and preserves raw relocation values in
`asm-values.bin`. Earlier failed fixture attempts remain under `build/`.

This is reference preparation toward public assembler and `CmpJoin` delivery.
Native bindings, global function-symbol fallback and goto records, branch-range
and diagnostic cases, exact heap accounting, allocation failures, partial-progress
exception unwind, assembler parsing, AOT file generation, and full compiler
self-hosting remain unqualified. No workflow or C1–C5 milestone count advances.
