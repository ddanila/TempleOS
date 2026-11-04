# Resident publication with inherited exception headers

The resident-source diagnostic previously declared SysTry, SysUntry and throw
inside every AOT control. This is needed in the early root phase, which has
system exports but no published public declarations. The later worker inherits
PublicDebug's resolved declarations. Repeating the declarations in that AOT
control reuses foreign metadata; the publication ownership checks reject it.

Temporary checkpoints isolate the old worker failure: control/frontend setup,
parsing and resident function/global address validation succeed, then the
publication assertion fails before unwind/execution. The frozen instrumented
source and terminal observation are in
`build/i386-resident-trace-minimal-v1/observation.json`. The shared AOT function
join searches inherited declarations, while frontend publication requires each
source entry to be parser-owned. Those ownership checks are unchanged.

The worker fixture now uses its inherited exception declarations. Before the
seven cases it requires resolved non-null SysTry/SysUntry/throw entries with
argument counts 2/0/2. After every case it requires the same declaration
identities, entry addresses and flags. The host verifier requires the initial
and final binding markers around all seven worker cases. The root fixture still
declares the helpers against system exports. All address/export/collision
rejection cases, metadata publication, direct resident call, actual try/throw/
catch execution returning 42, exact heap/reference/control/exception restoration
and answer-state checks remain intact.

## Verification and remaining gate

- `build/resident-headers-rebuild-v1.log`: both original bootstrap rebuild
  generations pass; these are not native C5 release generations.
- `build/i386-resident-headers-minimal-v1/source-audit.json`: 1,361 delivered
  source/document files match. The 386 boot audit also passes.
- `build/i386-resident-headers-smoke8-v1`: normal 8 MiB KVM 486 without FPU startup
  passes in 33.48 seconds, with live welcome/WinMgr, exact arithmetic/input-state
  pixels and unchanged provenance.
- `build/i386-resident-headers-minimal-v1/failure.json`: all fourteen resident
  cases and inherited-header preservation pass at the full gate's unchanged
  default 8 MiB. Both guest compiler recovery/program phases complete, the
  worker is released, and startup reaches live WinMgr and its completion marker.
  All fifteen modules other than CompilerProbe are byte-identical to the
  preceding candidate (`module-comparison.json`).

The complete host gate remains **fail** at `Read-only kernel startup changed
the disk`. An independent live-tree comparison finds only the new 114-byte
`/Registry.HC.Z` (attribute 0xC00). Existing file bytes/attributes/timestamps and
directory metadata are unchanged; the full live extent/bitmap audit passes.
The report pins this evidence and source/image/log hashes. The assertion has
not been bypassed; registry persistence and its relationship to the old
read-only startup expectation need qualification. Subsequent host assertions
and later regression stages have not run. Full minimal regressions and C1-C5
remain open.
