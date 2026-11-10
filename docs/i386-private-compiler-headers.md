# Guarded reads for private compiler interfaces

The on-demand lexer prototype reached compiler-support loading at 8 MiB, then
failed copying 12,717 bytes. That matches PublicDocument.HH plus its terminator.
A disposable caller-guard diagnostic confirms that its existing include guard
is already set: skipping the redundant read advances the failure to a
16,355-byte CompilerTypes.HH read. The declaration bodies would have been skipped
by their own guards, but the full file buffers were allocated first.

Private optimizer, parser, backend and JIT loading now use SystemCompiler.HH and
SystemLoader.HH. These are generated mirrors of the complete public interfaces,
with guard checks before dependency reads. A dependency is still included when
its guard is absent. Both original public guard names and every declaration,
parameter, default, include dependency and non-include byte are retained. The
private JIT loader also checks the document guard before its direct include.
All compiler/helper bodies and user-facing public headers remain unchanged.
Private binding declaration links can now name the generated interface files;
those files retain the original complete declarations for inspection.

`tools/gen-i386-system-headers.py` works on bytes to preserve legacy HolyC source
characters. Its `--check` mode is required by the host kernel build so changes to
the public interfaces cannot silently leave stale private mirrors. The generated
files are checked in for native rebuilding; ordinary source packaging includes
them with the other compiler headers.

```sh
python3 tools/gen-i386-system-headers.py
python3 tools/gen-i386-system-headers.py --check
```

## Verification

The production-source candidate under `build/private-guarded-production-v1`
changes only four runtime support sources and adds the two generated headers.
All resident modules, boot bytes, public headers and unrelated files remain
byte-identical. This is a source-loading change, not a new resident-code build.

- 8 MiB managed-pointer User regression: PASS,
  `user8/result.json`, SHA256
  7583d17e90008e6ef4c9a876c9f0352018e64322477e26f8e265cf95ee41b51e.
- Public optimizer at 16 MiB: PASS against the retained original reference,
  `optimizer16/result.json`, SHA256
  b276b3c811dc53670f1cc7f191285b4ab241ca553c3f183a045972171156a8d1.
- JIT fixups: PASS against the original reference,
  `jit/result.json`, SHA256
  c40bf059756408613e501d903fb1f1705928bd008a96eee19cbfd597ec87ef1d.
- AOT fixups: PASS against the original reference,
  `aot/result.json`, SHA256
  944aae6fee5bb733b3a6c52c6ab8a0602737e803b27b0cb5423752dce96818b9.

`build/private-guarded-audit-v1/result.json` passes, SHA256
f6708c0d1e7d67cc375a2090c133a42d8d5f0d6e85779135323aae3f46f040b3.
The independent audit reverses every generated include wrapper to recover the
byte-identical public source, reverses the private include substitutions to
recover the unchanged helper bodies, checks exact packaged files and rehashes
the regression inputs. Actual QEMU arguments confirm the reported memory
profiles. It does not claim full native-generation or startup qualification.

## Original-loop memory remains open

The current guarded files are also packaged onto the on-demand lexer V9 image
under `build/private-guarded-provider-v1`. Complete prompt, throw/compiler-error/
physical-break recovery and physical User reclamation pass at 64 MiB. The 8 MiB
User regression now bypasses both large redundant reads, but still fails an
80-byte public allocation before optimizer publication. The primary pool trace
shows used 0x1000F0 / allocated 0x100C00; its backing pool is fully allocated.
The specific allocating call still needs profiling. No memory limit, stack size,
lexer case or public interface was reduced to obtain the intermediate result.

The guard probe is under `build/compiler-header-guard-probe-v1`. The first
private-mirror experiment failed before generation because it treated a legacy
header as UTF-8; its empty-overlay run was interrupted and excluded. The corrected
byte-preserving experiment is `build/private-guarded-headers-v2`, followed by the
current production/provider candidates above.

The existing original-loop/ownership/on-demand patches still apply to main;
compiling or packaging them now uses these guarded support sources, so their
older image hashes remain historical identities. Original-loop production
integration, the 8 MiB allocation failure, broader compiler behavior, startup
budget and two current native generations remain required. C1-C5 and inventory
2/686 remain open.

Current candidate identities:

- Production-source disk SHA256:
  4920090770c1597a358541d4bf2bbb057c645ed7e630ade9260948fec2d557e7.
- Guarded provider disk SHA256:
  073ee72b19fed76cea7340254f798d83c0fc3b3c0a296dab707f428517db98c9.
- Provider `live-recovery/result.json`: PASS, SHA256
  64b0c99b54f3b99b0b09a9ecc6a3de9f60bf0d7da55a1921a173dba35cc3de21.
- Provider `user8/result.json`: FAIL, SHA256
  959c0f4466a71793c29ee970cbb404b4cc08e38f46935c53968da800ef4e4ab6.

These source-loading checks do not replace the next bootstrap rebuild or the
full current-source native build/install/resource qualification.
