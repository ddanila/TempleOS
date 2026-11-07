# Public DirFile search and ownership

`DirFile` is now a normal native public API in PublicFiles.HH. Console interface
249 appends `_DIR_FILE` at slot 662, preserving earlier slots. Kernel and native
console compile the same `Kernel/BlkDev/DirFileCore.HC`; DskStrA.HC includes that
body instead of keeping a second implementation. The source-loaded shared
compiler runner also reads this complete body.

The function preserves the original search behavior: first find the nearest
existing directory, then search candidates upward. A missing search returns an
independent copy of the first candidate. NULL name uses the directory basename
when an extension is present; an empty name is distinct. Leading extension dots,
already suffixed names, missing directory suffixes, relative/current paths and
root spelling follow the original. In particular, the tested missing root-file
default retains its original double slash rather than silently normalizing it.

The original miss path leaks `res` before advancing to the parent. The shared
body now frees that rejected candidate; its saved default is a separate copy.
Returned storage remains caller-owned. The pinned original reference retains
the weaker heap result as an explicit difference, never as the native oracle.

```
python3 tools/test-i386-dir-file.py --out build/dir-file-original-fresh
python3 tools/test-i386-dir-file.py build/IMAGE/kernel.img --out build/dir-file-native-fresh
```

The fixture uses a real nested filesystem tree with near, parent, ancestor and
missing matches. Twenty independent path cases also check input preservation,
and 512 repeated miss/parent searches check reclamation. It records all twenty
complete returned paths, each heap delta, cwd restoration and I64 width. Only
the actual drive letter is normalized for original/native path-byte comparison.

`build/i386-dir-file-original-v5` passes the original oracle. The repeated pair
leaks 61,440 bytes; the individual deltas expose precisely the rejected candidate
allocations. `build/i386-dir-file-api-baseline-v3` rejects the first DirFile use
before execution on the old image. Initial v1 probes contained an unsupported
conditional operator; original v2 then exposed an uninitialized fixture output
counter. Those runs and their terminal audits are retained as fixture failures,
not API behavior. Native v1 reached every individual case but timed out before
repeat completion; its screenshot shows a busy command. The instrumented follow-up
uses partial exports, repeat progress and a larger observation window.

This is a stable-filesystem, valid-allocation contract. Allocation-failure,
invalid-drive, concurrent mutation and complete DskStrA/stream/compiler delivery
remain outside its qualification scope.

The final normal native run `build/i386-dir-file-native-v2` passes all 44 words.
All twenty paths match the original's complete 533 normalized bytes, SHA-256
`78b017cc903e2aa58039f6da834dc4af49ea2b7908d8fe00347954adb61afcee`.
All 21 native heap deltas are zero, including the 512-search phase. Independent
terminal audits verify current inputs and the complete path comparison. The
longer observation window is not a performance-budget qualification.

Both x64 bootstrap generations and the full 1,763-source build pass. The 26-stage
shared compiler suite passes every earlier regression, all sixteen executor
observations and all nine stream observations, with 1,039 independently checked
inputs. Carry and ClassMeta repeat their unchanged whole workflows and exact
original documents. Fresh 8 MiB normal and 16 MiB diagnostic boots each match all
307,200 welcome pixels; the latter passes both program, ownership and file-break
cleanup phases. See build/i386-dir-file-memory-audit-v1.json. Compiler runtime
remains 88; console is 249; the native kernel remains 454,184 bytes.

The inventory maps these scoped component results to DskStrA.HC while leaving
whole-file qualification open. Normal public compiler/stream delivery, 684
inventory items and complete C1–C5 release gates remain unfinished.
