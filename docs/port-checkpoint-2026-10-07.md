# Port checkpoint — 2026-10-07

This checkpoint preserves ongoing work, not a release or completed milestone.
Work remains on `main` in `https://github.com/ddanila/TempleOS`, based on
`fd1ab3638574a42cce673a5b7d6c0c55000ba717`. No branch or PR was created.

## Implemented

- Native bare inline assembly and a maintained saved-source/AOT execution test.
- Exact class publication journals and a two-bit frontend selection map, with
  additional constrained-memory and ownership checks.
- Smaller parsing/output contexts and conditional floating-helper storage.
- Frontend optimizer scratch release while preserving the public optimizer's
  retained-stack contract and borrowed storage.
- Runtime floating-context regression coverage and selectable 8/16 MiB
  execution-answer testing.

## Verified scope

| Snapshot / evidence under `build/` | Result |
| --- | --- |
| `i386-output-phase-bootstrap-v69-runner.log` | Two-generation bootstrap and source/generated-binary hash checks pass |
| `i386-output-phase-cross-v69/result.json` | Native cross-build and 386 instruction audit pass |
| `i386-output-bound-compact-diag-v69-16m/result.json` | 22 class + 28 program publication cases and nine runtime/VGA commands pass |
| `i386-output-bound-compact-float-v69-16m/result.json` | 16 integer/F64 commands pass on `486,-fpu` |
| `i386-conditional-helpers-bare-v69-16m/result.json` | 13 saved assembly execution commands pass on the earlier snapshot |
| `i386-output-phase-boot-v69-8m/result.json` | FAIL: 4,096-byte allocation; heap used `0x65B0A0` of `0x65C200`, largest block `0xE18` |
| `i386-bare-assembly-full-build-oom-v69/result.json` | Earlier full native build FAIL: OutMem compiling `DocRecalcCore.HC` at 16 MiB |

Passing older snapshots do not qualify the latest source as a complete OS.
The phase-logging image SHA256 is
`7c4f9b7d8ce2820b768c1d1c3d435c5f99c2963d17ba3ecfad9bac0a336046de`.
Its output markers finish before the next allocation rejection; the exact
caller of that final 4,096-byte request remains unproven. No tests remain running.

## Worktree state and next work

Output-phase logging in `Compiler/I386/Frontend.HC` is temporarily unconditional
for attribution. Kernel caller tracing is disabled by default; optional tracing
hooks remain. Restore selective output logging before final qualification.
No compact optimizer-stack implementation has been made.

Next: identify and fix the remaining bounded-memory failures without changing
HolyC semantics or public ownership contracts. Requalify normal 8 MiB startup,
16 MiB diagnostics, floating and assembly execution, then complete native module
builds and successive self-hosted generations/install tests. Full original OS
functionality and release gates remain open. Physical hardware verification and
trivial manual acceptance remain deferred in favor of QEMU automation.

## Preservation

The initial session made `.git` read-only, so the first wrap-up could not commit
or push. Permissions were subsequently restored and this checkpoint is being
committed on `main` for push to the user fork. A recovery archive in `build/checkpoints/2026-10-07-wrap-up/`
contains tracked and nonignored source files, a binary diff against HEAD, selected
build/test evidence, and SHA256 manifests. Generated disk images stay in their
existing build directories and are not duplicated in the archive. The archive is local preservation; it predates this permissions-note update and
is not included in Git. Source and documentation are included in the checkpoint
commit; ignored build artifacts remain local. Earlier dated notes are historical;
this checkpoint supersedes their pending/running status descriptions.

Commit preparation: the tracked-file whitespace check passed, but the full staged
check also covered new files and reported blank lines at EOF, mixed indentation,
and trailing spaces (including preserved patch context). These are retained to
avoid changing tested source snapshots during checkpointing. No runtime tests
were rerun solely for the commit.
