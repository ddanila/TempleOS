# Nested assembly error ownership

The shared `CmpJoin` catches an inner assembly `Compiler` exception long enough
to release that join's owned scope. It then restores the parent packet/control,
hash context, depth and code stack before rethrowing `Compiler`. The enclosing
normal buffer join retains its existing error-reporting and NULL-return policy.
The parser, assembler, resolver and successful packing bodies are unchanged.
Other exception kinds keep their existing propagation behavior; this change
does not qualify allocation failure or arbitrary exceptions.

```sh
python3 tools/test-i386-public-buffer-errors.py IMAGE --assembly-errors --out OUT
python3 tools/test-buffer-errors-original.py --assembly-errors --out OUT
```

The nested fixture uses the same public CmpBuf accounting and global-output
isolation as [the ordinary buffer error contract](i386-public-buffer-errors.md).
It covers a missing operand, emitted prefix, unresolved label, out-of-range short
branch, failure after another inline block, function argument, pending goto,
defined label, completed preceding function, and a pending imported-call fixup.
All execute the delivered parser/assembler through normal APIs.

The pre-change native image in `build/i386-buffer-nested-baseline-v3` retains
67,056–67,336 bytes in each reported caller counter in nine cases; the unresolved
label fails later without retention. Returned NULL, error/warning counts,
borrowed source, queue and fresh valid compilation are recorded independently.
The actual original x64 Cmp entry point retains 68,216–68,528 bytes in nine
cases. The two counters are raw observations and must not be summed as separate
physical storage.

The unresolved-label case has a deliberate separate oracle: original x64 emits
an unresolved reference and returns zero errors, while native rejects it with
one error. This existing difference is preserved and remains an assembly/module
compatibility gap. It is not counted as a newly qualified equivalent behavior.
The original probe checks its unresolved-reference diagnostic explicitly.

The canonical final native receipt is
`build/i386-buffer-nested-after-v2/result.json`: all ten caller deltas are zero,
error counts are unchanged, queue/input/recovery checks pass, and task backing
and global diagnostic-owner accounting restore exactly. The same expanded
fixture is retained with the unchanged image in the baseline above.
`build/buffer-nested-original-before-v5/result.json` and
`build/buffer-nested-original-after-v3/result.json` preserve all ten original
outcomes while restoring the nine failing caller heaps exactly. The full
81,920-byte before/after diagnostic buffers are byte-identical.

## Caller-owned state

A separate public CmpJoin probe supplies a parent packet/control and two caller
code graphs separated by a saved code frame. Missing-operand, short-range and
pending-import errors must propagate Compiler while preserving the parent
objects, hash context, depth, both code headers, instruction values and misc
records. Caller cleanup uses public code-stack/control APIs; it does not repair
join-owned packet/hash/assembly state. Caller heap deltas are measured after
that cleanup.

`Boundary.HC` runs three propagated-error cases with two caller code frames.
The final receipt passes all twelve structural assertions and zero heap deltas
in each case. On the unchanged image, parent packet/control, depth, hash context
and active code graph checks fail, with 71,200–71,480 bytes retained per caller
counter even after normal public code/control cleanup. Saved outer-frame storage
stays intact in both images; it must become active again before propagation.

The probe records changed lexer flags rather than claiming full rollback. It
checks immutable target/AOT/buffer-ownership bits. Reusing the failed parser for
continued compilation remains unqualified, as do interrupted fixups, partial
headers, setup/map/packing failures, cancellation and concurrency. Full assembly
coverage, desktop/apps, resource/performance gates and native C5 release
generations remain open. C1–C5 stay active at 2/686 bundled qualification.


## Verification and remaining qualification

`build/i386-nested-asm-cross-v1/final-verification-audit.json` checks the exact
production diff, all 1,849 source/26 helper pins, sixteen native modules, both
original bootstrap generations, identical before/after fixtures, raw records,
unchanged error counts and original diagnostic buffers. The prior ten ordinary
failure cases pass on native and original x64. The final native image also
passes fourteen successful buffers, the complete assembly contract, all 46
prior compiler-error rows, ten DolDoc boundary cases and six independent ELF32
packets. ABI remains Compiler104/Console264/Memory41 with 691 exports and 22 mask
words. These scoped checks do not complete C1–C5.
