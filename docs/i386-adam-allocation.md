# Adam-owned allocation helpers

MemoryRuntime 31 publishes the four original helpers AMAlloc, ACAlloc,
AMAllocIdent and AStrNew. Their complete bodies are shared byte-for-byte with
`Kernel/Mem/MAllocFree.HC` through `Kernel/Mem/AdamAllocCore.HC`; native calls
use the existing owner-aware memory provider and `adam_task`.

The pinned-original contract passes mask 31 in
`build/i386-adam-alloc-reference`, with unchanged inputs. A child task checks
Adam-heap ownership, zero-filled allocation, identity copying including NULL,
string copying including NULL, and its own source allocation's ownership. The
fixture frees its allocations; it does not qualify allocation failures or
concurrent heap activity. Both original rebuild generations pass. The
cross-build and 386 audit pass with 1538 source and 24 build-input hashes
unchanged in `build/i386-adam-alloc-cross`. The 64 MiB native contract passes
all three commands and mask 31 with unchanged inputs in
`build/i386-adam-alloc-native`. Its 63.966931-second startup observation was
concurrent with other guests and is not a timing gate. The 8 MiB functional
contract also passes all three commands and mask 31 with unchanged inputs in
`build/i386-adam-alloc-native-8m`; its 63.864951-second startup was concurrent.
Isolated startup and diagnostic gates remain unqualified. These services are prerequisites
for full block-device initialization, which remains unimplemented natively.

```sh
python3 tools/test-i386-adam-alloc.py --out ORIGINAL
python3 tools/test-i386-adam-alloc.py IMAGE --out NATIVE
```

The committed candidate's isolated 8 MiB gate passed all nine behavior/VGA
checks with no build-provider loads and four unchanged inputs, but missed the
60-second startup budget at 62.845757 seconds (`build/i386-adam-alloc-startup`).
Its 16 MiB diagnostics pass in `build/i386-adam-alloc-diagnostics` at
231.902702 seconds, with 128 immediate-push, 22 publication and 28 program
publication cases, both memory phases, nine behavior/VGA checks, no build
provider and four unchanged inputs.
