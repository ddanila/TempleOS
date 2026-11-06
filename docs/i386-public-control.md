# Public compiler-control ownership

Native console interface 226 exports the original `CmpCtrlNew`, `CmpCtrlDel`
and `CmpCtrlSize` signatures. `Compiler/PublicControlCore.HC` contains the exact
constructor, destructor, size accounting and allocator adapters formerly at
the start of `Compiler/Lex.HC`; both original compiler and native console
include it. Public controls use public allocations throughout. The private
native compiler's arena controls and their validation are unchanged.

The console binds the kernel's existing no-at-sign bitmap directly for
`CCF_KEEP_AT_SIGN`. It does not copy input buffers or add the private target
flag to public controls. `CmpCtrlSize` retains original allocated-size accounting
and excludes borrowed root buffers. The export array grows from 612 to 615;
its existing 20-word data mask still covers every entry.

## Checks

`tools/test-i386-public-control.py` compares twelve 64-bit results against an
independent all-ones table. The fixture checks control self-links and flags,
input pointer identity, current-task symbol tables, filename/line initialization,
owned and borrowed size accounting, prompt-buffer allocation, at-sign behavior,
explicit absolute filenames and restoration of public heap usage.

```sh
python3 tools/test-i386-public-control.py --out ORIGINAL_OUT
python3 tools/test-i386-public-control.py IMAGE --out NATIVE_OUT
```

The original run in `build/i386-public-control-original-v1` passes all twelve
checks with unchanged execution inputs. Its builder helper was subsequently
updated to require the three new function exports; the historical hash is
preserved. `build/i386-public-control-source-parity-v1.json` verifies the shared
block byte-for-byte against the pre-change source. Both bootstrap generations
pass in the public-control v1 run.

Public Lex and LexExtStr, full song loading, error/unwind behavior and application
interaction remain separate work. Constructor success alone cannot qualify the
24-check lexer oracle or the C1–C5 milestones.

## Public type visibility correction

The first native candidate resolves CmpCtrlNew but rejects `cc->flags` because
its public headers expose only the task header's forward declaration of
CCmpCtrl. The constructor and lexer v1/v3 failures are preserved. PublicDocument
now includes the shared CompilerTypes header so callers see the actual layout.
The direct native include and sizeof probe in
`build/i386-public-control-types-probe-v1` passes without changing its input
image. Both bootstrap generations pass again in
`build/rebuild-public-control-v2-verified`.

The first candidate's 8 MiB welcome/clear/input run passes with unchanged inputs;
that result precedes the public type header correction and does not qualify it.

## Default filename initialization correction

Native constructor v2 executes all twelve checks, but fails only the default
filename/line check. The detail probe reports line number one and an empty
constructor filename. Source inspection confirms the public block globals never
initialized `tmp_filename`; the private file compiler already held the intended
temporary filename. Console setup now borrows that existing kernel-lifetime
filename for the public block globals before publishing them. This supplies the
original constructor with its required global state instead of changing its
shared behavior. The fixture now explicitly requires both filename pointers to
be non-null before comparing them.

The lexer v4 run reaches the missing Lex call on fixture line 12; no lexer
behavior assertions execute. The corrected-header candidate's 8 MiB
welcome/clear/input check also passes with unchanged inputs, before the filename
initialization fix. All historical failures are retained.

## Final constructor candidate

`build/i386-public-control-original-v2` and
`build/i386-public-control-native-v3` both pass all twelve checks with unchanged
execution inputs; the native run also executes fresh arithmetic and checks its
pixels. `build/i386-public-control-cross-v3` passes the instruction audit and
matches all 1,724 source and 26 helper hashes. Both bootstrap generations are
preserved in `build/rebuild-public-control-v3-verified`.

`build/i386-public-control-welcome-v3` passes exact welcome pixels, suspended
clear and subsequent input at 8 MiB TCG with unchanged inputs. This does not
close the separately recorded full-diagnostic memory failure.
