# Bounded compiler diagnostic providers

An attempted 8 MiB run of the monolithic compiler diagnostic exhausted the
kernel arena while compiling the native module-pack bundle
(`build/i386-mount-path-cross-v5/boot/debug.log`). Previous image manifests did not establish an 8 MiB diagnostic pass; the
plan distinguishes 8 MiB interactive and 16 MiB rebuilding configurations.
The compiler and console remain resident; diagnostic code can be reclaimed between independent groups.

CompilerProbe now contains the lexer/parser, publication, input and public-header
checks. CompilerProgramRuntimeProbe contains the complete unchanged ProbePrograms
body and its program, module, allocator, file and formatter self-hosting vectors.
The shared report, symbol lookup/removal and program-read helpers preserve their
original bodies. Common imports are shared; each provider has an exact import
contract, and their union is the original 29 imports.

Each provider runs in both original phases: synchronous boot and the diagnostic
worker after IRQ/task and file-channel activity. Both use the same 80-byte probe
record, version 20. The worker retains its original 1 MiB private compiler arena
and 16 KiB stack, and the default diagnostic remains 8 MiB. An explicit diagnostic-only memory
option records the established 16 MiB rebuilding profile; ordinary interactive
checks retain their own limits. No instruction allowlist or
program vector was removed. The primary keeps about 739 KiB of file capacity for its 692 KiB logical
image; the program image is about 447 KiB. Their combined code is not retained
during compilation. Normal module loads still compact to their original size
and preserve their six-argument public ABI. The diagnostic reservation prevents
console allocations from occupying the metadata tail needed for a later reload.

The primary provider is loaded before console allocations, released after its
boot checks, and reserved again before root headers fragment the kernel arena.
It is released before the program provider loads. The worker follows the same
release-before-load sequence. Module allocations, backing ownership, compiler
controls, task references and interrupt state are checked. The program provider's
worker load owns the real mounted-volume I/O session.

The host verifier requires both providers' placement and exact reclamation in
each phase and retains all existing functional trace checks. Rejection fixtures
cover wrong target, missing import and wrong API for each provider. The ordinary
startup fixture corrupts both diagnostic modules and must still reach the real
console: normal boot must not depend on diagnostics.

The first split run passed the previously failing native bundle and the rest of
its boot program group, then exposed reload fragmentation: a compacted code allocation was smaller
than the original file that must be loaded again. Reservation was moved before
root headers and now retains the validated file capacity. The final staged image completes both providers in both phases at 16 MiB.

The 8 MiB diagnostic now reaches full root-user-header loading but still
exhausts memory there (`build/i386-mount-staged-cross-v4`). This remains a failed
profile, not a passed gate. The 16 MiB native trace reaches DONE after root headers, scalar checks and
worker release (`build/i386-mount-staged-cross-v6/boot/debug.log`). Its current
compiler/task/allocator driver assertions pass in
`build/i386-mount-core16-v6/result.json`. The offline validator explicitly excludes
the disk immutability assertion: first startup adds `/Registry.HC.Z`. An independent
walk confirms all existing file bytes, attributes and timestamps and all directory
attributes/timestamps remain unchanged, and the resulting extent bitmap is valid.
This is not a full `build-i386-kernel.py --test` pass. Initial VGA capture timing
and the first-run registry/read-only fixture remain open full-driver gates.

The host checker now accounts for all 40 inline opcode keyword records, the
344-byte compiler control and 72-byte lexical file records, and all eleven
publication vectors. These correct stale expected sizes/counts without dropping
functional checks. The explicit `--diagnostic-ram-mib 16` option does not change
the default 8 MiB diagnostic or interactive profiles.

The source-help pixel oracle now follows NativeHelpDraw's 59-row viewport and
compares all 640x480 pixels, including the blank final row. The focused live
WinMgr help group passes on the final image at 64 MiB KVM
(`build/i386-mount-help64-kvm-v2/result.json`). The historical media workstation
run failed on the unbounded host oracle; the copy run was interrupted after the
same guaranteed host failure was identified. Neither is a suite pass. A fresh
full workstation run uses frozen real harness/reader inputs at
`build/i386-mount-workstation64-kvm-v1` and is still in progress.
