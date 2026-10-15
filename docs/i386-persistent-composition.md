# Automatic persistent graphics over ordinary documents

Console 89 is a C2/C4 development candidate. It admits the original compositor
when the persistent `gr.dc` bitmap contains a nontransparent byte, even if the
shown terminal document is plain and no draw/final callback is installed.

## Contract and implementation

Original screen layering composes ordinary document text, the retained persistent
bitmap and then the final-screen hook. Direct public `gr.dc->body` writes must
participate: an API-only dirty flag would miss a supported way to draw.

Admission first checks existing document/control/hook reasons. Otherwise it
scans the fixed, root-owned 640×480 bitmap as 32-bit words for any byte other than
TRANSPARENT. It allocates nothing and does not yield or retain foreign pointers.
The normal manager still acquires its frame lease and revalidates admission
before composing. Raw and focused retained private views retain their existing
priority; their complete original-system parity remains separate work.

After a per-window update by the actual manager, an eligible terminal
whose default document was rendered selects document presentation permanently.
This avoids reviving a stale retained text surface when the last persistent
pixel or final hook disappears. Explicit component presenters do not perform
this transition. Hidden/inhibited documents and retired tasks are excluded.

Public CTask/layout/export counts and the 48-byte console service table are
unchanged. Memory stays version 25. The ordinary console still uses its retained
projection until original composition is needed; complete ordinary cursor/input,
focus/raw/debug and event semantics remain C2/C4 work.

## Independent test-first evidence

```sh
python3 tools/test-i386-persistent-window-reference.py --out REF
python3 tools/test-i386-persistent-window.py IMAGE --out NATIVE
```

The native test keeps the existing terminal document in both put/display roles,
resets only its fixture contents, and uses a plain heading with hidden cursor.
It writes a red pixel directly into the persistent body and waits through public
Refresh. A second phase changes it to blue and installs a final hook that covers
it with green. Removing that hook must reveal blue; clearing the persistent
pixel must restore plain white. Each phase compares the complete independent
640×480 font/palette framebuffer, with no explicit presentation calls. Cleanup
restores the header, accepts `6*7`, and checks 42 with the already established
original prompt colors.

The pinned original passes eight observations in
`build/i386-c1-persistent-window-reference/result.json`:
`[4,0xF050,2,0xF050,1,0xF050,15,0xF050]`. Each pair is the packed pixel and the
first plain-document P text cell. Inputs are unchanged.

The Console-88 image fails the first native red-pixel/plain-document observation
in `build/i386-c2-persistent-window-red/result.json`, with unchanged inputs.
The guest reaches `PG A`; later layering/clear/input phases are not executed.

The first Console-89 cross-build fails at a missing forward declaration for the
terminal composition helper in WindowList. A prototype repair is under build;
this failed build does not qualify an image. Native layering, startup cost of
bitmap scanning and regressions must pass before claiming the candidate.

## Console-89 candidate evidence

The repaired cross-build in `build/i386-c2-persistent-window-cross-prototype`
passes, with all 1473 source/build hashes matching the worktree. Its original
two-generation bootstrap and limited 386 boot instruction audit also pass.
Public exports remain 228 and the console service table remains 48 bytes.

`build/i386-c2-persistent-window-green/result.json` passes all twelve native
commands with unchanged inputs. All four layering/clear frames, restored header,
green command/result/prompt pixels and continued arithmetic match. The passing
reference and prior Console-88 visual failure above provide paired evidence.

`build/i386-c2-persistent-window-startup/result.json` passes all nine startup
commands at 8 MiB in 49.404 seconds (`486,-fpu`, QEMU TCG), with WinMgr enabled
and no build-provider loads. This is one passing measurement against the existing
60-second budget, not a general graphics throughput benchmark.

The preceding ownership candidate's unpaused editor/help/navigation run passes
214 commands in `build/i386-c2-document-role-private-views/result.json`, preserving
its source image. Separate runs on the palette-fixed Console-88 image and this
Console-89 image remain active at this checkpoint:
`build/i386-c2-terminal-palette-private-views` and
`build/i386-c2-persistent-window-private-views`. Do not transfer the old image's
pass to either current candidate. Held-frame/manager-restart and remaining
current-image regressions are recorded separately as they finish.

C1–C5 remain open. Next retain private-view and frame-lifetime regressions, then
continue ordinary cursor/input/event semantics and original GetStr integration
needed by unchanged TimeClock source. This slice does not qualify native release
generations, all graphics modes, apps or the full desktop.

`build/i386-c2-persistent-window-frame/result.json` now passes all fourteen
held-frame and actual manager-death/restart commands, with unchanged inputs.
This preserves scoped REFRESH_IN_PROGRESS release and completed-frame accounting
through the new composition admission path. It does not replace the still-running
full private-view regression.
