# Default registry packaging and persisted startup

Normal registry initialization retains the original RegInit/RegDft behavior:
a missing writable registry is created with Adam/SysMsgFlags and Adam/SysRegVer
branches. The old build image omitted that file, so a successful startup wrote
`/Registry.HC.Z` and failed the full gate's exact disk-immutability assertion.

The source-image packager now includes the original default registry, generated
by actual RegInit on the original cross-compiler OS. The generator temporarily
uses a fresh writable document, runs the original initializer, checks both tree
branches, reads the saved file and checks its original CompressBuf/ExpandBuf
round trip. Export buffers stay live until host capture. The original document
and archive must match the pinned fixture exactly before packaging. The new
file has compressed attribute 0xC00; the independent volume verifier permits
that attribute only for this explicit packaged path. The disk-immutability
assertions are unchanged.

The independently captured default is 132 DolDoc bytes including the final
0x05 marker, containing `sys_msg_flags[0]=0;` and
`registry_version=5.030;`. Its original 114-byte type-2 archive has SHA-256
`c7953f8f8b5ed44c10ef60a66a8782b29bc524c46040b82c234eecb84f89f296`.
Both the document and compressed bytes match the native missing-file startup
output. The fixture is in `tests/i386/startup-registry-reference.json`.

## Reproducible evidence

```
python3 tools/test-i386-startup-registry-reference.py --out build/FRESH-reference
python3 tools/build-i386-kernel.py --test --compiler-qmp-stdio --out build/FRESH-build
python3 tools/test-i386-startup-registry.py build/FRESH-build/kernel.img --out build/FRESH-native
```

Use fresh output directories. The standalone reference restores the pinned
original OS with the established repair revision, rather than using current
native code as its expected result.

- `build/i386-startup-registry-reference-v5/result.json` passes exact original
  document/archive capture with unchanged inputs. The earlier v1 attempt did
  not call the initializer pointer correctly; v2/v3 freed exported buffers too
  early and are not valid archive captures. Corrected v4 also expands the
  native-created archive on the original OS and proves exact document parity.
- `build/i386-startup-registry-native-v1/result.json` passes three actual persisted
  8 MiB KVM 486 without FPU boots. The first checks values and Adam ownership,
  then deletes the file through public FileDel. The next boot recreates exactly
  the original archive. The third leaves the entire disk byte-identical.
  Every boot checks welcome/live WinMgr, value/ownership and arithmetic pixels,
  unrelated live files/metadata, and complete filesystem extent/bitmap integrity.
  Startup takes 33.33, 33.23 and 33.23 seconds. Source inputs remain unchanged.
- `build/i386-seeded-registry-minimal-v1/source-audit.json` passes all 1,361
  delivered source/document files. Boot/386 and live JIT audits pass. All sixteen
  compiled module files are byte-identical to the preceding resident-header
  candidate; no runtime code, RAM, worker budget or application workload changes.
  The existing original bootstrap remains source-current; no new native release
  rebuild generation is claimed.

## Remaining gate

The complete default 8 MiB build gate reaches guest root/worker compiler/program
completion, worker release and live WinMgr startup. Exact diagnostic-disk
immutability now passes, as do the following host compiler/program checks. The
next terminal failure is `VGA console mismatch`: the old verifier compares the
diagnostic screenshot to a static four-line console. The actual startup runs
WinMgr. This next failure needs inspection and an appropriate independent visual
oracle; the comparison has not been bypassed.

`build/i386-seeded-registry-minimal-v1/failure.json` pins the images, sources and
terminal logs and records independently reconstructed exact diagnostic-disk
identity. Later keyboard, rejection, installation and other full-gate stages
have not run. Full minimal regressions, all application qualifications and
C1-C5 remain open.
