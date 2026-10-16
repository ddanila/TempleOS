# Original device-context loading and archive expansion

The candidate integrates the complete original `DCLoad` and `ExpandBuf` bodies,
including original archive-control allocation and release. Both extracted cores
match their pre-extraction source byte-for-byte. The native expansion path uses
the existing retained dictionary-entry service, the shared original expansion
loop, and a portable bit-field reader. The memory bound is a native
`mem_mapped_space` global initialized from the arena's upper address before
public console services run. Results and temporary codec allocations use the
original task-aware allocation calls.

ConsoleRuntime 130 appends public `DCLoad` and `ExpandBuf` bindings. The console
loader adds the existing `I386ArcEntryGet` dependency with matching array capacity
and binding count. Existing public export indices remain unchanged.

The fixture generates four GR buffers with original `DCSave`: raw pixels with
standard/custom palettes and 7-bit/8-bit compressed pixels with standard/custom
palettes. The generator checks the compression types. The common loader checks
all 512 pixels of each buffer, dimensions, padded width, origins, date, consumed
size, palette values, reset matrix, thickness, signature and scale. Explicit
parent-task ownership must use a distinct non-NULL task. Mutating and freeing
the input buffer leaves the loaded bitmap intact. The direct `ExpandBuf` cases
check empty/raw output, byte copies and NUL termination, a parent-task allocation,
invalid types 0 and 4, oversized expansion rejection, and a successful call after
the exceptions.

Pinned-original and rebuilt-original controls pass all eleven checks (load mask
63, expansion mask 31), with unchanged execution inputs and identical hashes
for all four generated GR buffers:

- `build/i386-c2-dc-load-full-reference/result.json`
- `build/i386-c2-dc-load-full-rebuilt/result.json`

The rebuilt control verifies every source and compiler/kernel binary against the
bootstrap manifest before building its image. Merely overriding kernel source
in an ISO would not replace the running kernel's expansion implementation.

The old Console-129 image rejects the preceding loader fixture at the missing
DCLoad binding in `build/i386-c2-dc-load-native-red`, with unchanged execution
inputs. Its exact fixture and runner are archived in the result directory.
Earlier fixture attempts used conditional expressions unsupported by the
original HolyC parser; explicit branches replaced them. The initial native
cross-build attempts exposed unsupported `#undef` directives in the new adapter.
Their expanded tokens initially looked like failures in the memory-bound
expression. The adapter now follows the existing module convention of retaining
its aliases through the compilation unit and uses a real memory-bound global. These failures are retained under
`build/i386-c2-dc-load-reference`, `-shared`, `-cross`, `-bound-cross` and `-global-cross`.

The final bootstrap and cross-build pass with all 1520 source and 24 build
inputs unchanged in `build/i386-c2-dc-load-alias-cross/input-audit.json`.
The native four-command suite passes all eleven checks with unchanged inputs
in `build/i386-c2-dc-load-native`. The existing six-check bitmap insertion suite
also passes on the final image with all four exact sprite buffers and unchanged
inputs in `build/i386-c2-dc-load-bitmap-regression`. Resource qualification is
pending. GRRead, DocGR, complete
Type, original terminal startup and C1–C5 acceptance remain open. This suite does
not qualify malformed compressed dictionary streams or complete source files.

```sh
python3 tools/test-i386-dc-load.py --out ORIGINAL
python3 tools/test-i386-dc-load.py --shared --out REBUILT
python3 tools/test-i386-dc-load.py IMAGE --reference ORIGINAL --out NATIVE
```
