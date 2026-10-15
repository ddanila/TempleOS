# DocEd document-owner retirement

These C4 integration contracts use the delivered Console 95 public DocEd path.
They do not qualify the complete editor, forms, menus or release generations.
The tested image is `build/i386-c2-doced-worker-defines-cross/kernel.img`.

## Independent tasks and two lifetime points

The parent creates two sibling tasks. The document belongs to the first task's
heap, and the second task edits it with real DocEd. The parent retires the owner
with Kill(owner,TRUE,FALSE). Normal descendant retirement cannot explain editor
termination, because the editor is not the owner's child.

| Lifetime point | Original shared-system control | Native requirement |
| --- | --- | --- |
| Inside initial DocRecalc's tag callback | Mask 11; editor remains alive after owner retirement | Mask 31: callback entered, owner and editor retire, editor does not return normally, parent roles survive, and the editor end hook observes the owner and document allocation still live |
| Waiting in View after document/border binding | Mask 11; editor remains alive after owner retirement | Mask 15: active editing observed, owner and editor retire, editor does not return normally, and parent roles survive |

The callback-held fixture is
`tests/guest/i386-doced-owner-reference/DocEdOwner.HC`. Its end hook checks
TaskValidate(owner), MHeapCtrl(document)==owner->data_heap and the document
signature before editor teardown proceeds. This strengthens the ordering check;
it is not a measurement of final heap recovery.

The View-waiting fixture is
`tests/guest/i386-doced-view-owner-reference/DocEdOwner.HC`. Its tag callback
returns normally. The parent waits until the editor's display and border roles
are bound, and both sibling windows are hidden. Thus retirement is tested
outside the initial DocRecalc callback, without relying on a visible manager
render to hold the edited document. This exercises the outer DocEd lease.
Neither fixture dereferences the retired document afterward. The failing
original leaves its editor in the callback or awaiting input until the isolated
reference VM stops; it is not resumed onto freed document state.

## Evidence and commands

The shared-original controls fail with unchanged inputs:

- `build/i386-c4-doced-owner-order-before/result.json`: [11], expected [31].
- `build/i386-c4-doced-view-owner-final-before/result.json`: [11], expected [15].

The native tests pass with unchanged inputs, continued arithmetic, and exact
persisted fixture bytes:

- `build/i386-c2-doced-owner-packed/result.json`: five commands, mask 31.
- `build/i386-c2-doced-view-owner-packed-final/result.json`: five commands, mask 15.

Both use 64 MiB, QEMU TCG and 486,-fpu. Run them with fresh output directories:

```sh
python3 tools/test-i386-doced-owner.py build/i386-c2-doced-worker-defines-cross/kernel.img --out build/new-doced-owner
python3 tools/test-i386-doced-view-owner.py build/i386-c2-doced-worker-defines-cross/kernel.img --out build/new-doced-view-owner
```

The paired original runners accept --current-system and require a passing,
source-matched original rebuild. Their failure is an explicit original/native
lifetime difference, not an omitted required case.

## Fixture staging

The final runners use the existing package-i386-native-image.py additive
packager to put the exact shared fixture on a fresh image copy before boot.
Actual guest #include still compiles and executes it through the normal file
and HolyC interfaces. Each runner pins the fixture, image, packager, independent
filesystem reader and input tool, records the packaging report, and checks the
persisted fixture bytes again after execution. Original file bytes/attributes/
dates and the boot area are preserved; the base image remains unchanged.

This removes interactive fixture upload rather than changing the tested owner
or editor behavior. Earlier upload runs pass the same contracts in 33 and 30
commands; the final runners need five each. The existing application packaging
regression also passes on this image, including byte/metadata/boot preservation,
empty/binary payloads, idempotence and six rejection cases. No runtime OS source
changed for this checkpoint.

## Remaining lifetime gates

These cases qualify retirement of the edited document's memory owner at the two
specified points. Saved-role retirement outside the View cases below, recovered cancellation with
a live caller, restoration interrupted by
another exception, late input/data-scan failures, allocation failures and precise
teardown heap accounting remain open. Retiring while manager frames borrow a
temporary border also needs its own gate. TaskValidate becoming false is not
proof that every backing allocation has been reclaimed. C1–C5 remain incomplete.

## Saved-role owners and the original parent (Console 96)

`tests/guest/i386-doced-saved-role-reference/DocEdSavedRole.HC` keeps the edited
document in the parent task's live heap. A separate sibling owns a saved put,
display or border document. The editor binds that role, then enters real DocEd
and waits in View. Retiring the saved-role owner must stop the independent
editor while leaving the edited document valid, unlocked and attached to its
original window owner. The parent task's roles must also survive.

This exposed a committed-teardown bug in Console 95: the saved display owner
retired and the editor stopped, but DocEd's temporary parent_doc still pointed
to the retired display. The framebuffer in
`build/i386-c2-doced-saved-role-red/qemu/startup-command-04.ppm` shows 127 instead
of 255; its inputs are unchanged. A stricter rerun rejects RoleLife immediately
in `build/i386-c2-doced-parent-fast-red`. Targeted --case 3 and --case 4 runs on
the old image also fail in `build/i386-c2-doced-parent-lease-red` and
`build/i386-c2-doced-live-parent-red`.

Console 96 captures the original parent_doc and leases it as a fifth document
resource. During committed teardown, it undoes DocEd's automatic parent binding
when that binding is still present. A live original parent is restored; an
original parent whose owner is closing or whose document is retiring is cleared.
A callback's different parent binding is preserved. Ordinary/recovered DocEd
parent behavior is unchanged. Public layouts, 231 console exports, the private
48-byte services and Memory 25 remain unchanged.

The six cases require mask 255:

| Case | Retired owner or restored link |
| --- | --- |
| 0 | Saved put owner |
| 1 | Saved display owner; the surviving document must not keep its dead parent |
| 2 | Saved border owner |
| 3 | Original parent owner, after DocEd temporarily replaced that parent |
| 4 | Saved display owner; preserve a separate live original parent |
| 5 | Saved display owner; preserve a different live parent selected by a real View tag callback |

Mask bits check active View binding (1), owner retirement (2), editor retirement
without normal return (4), parent-task roles (8), surviving edited-document
signature/heap (16), unlocked state (32), original window owner (64), and correct
parent link (128). The failing shared-original control returns
[187,59,187,187,59,155] with unchanged inputs in
`build/i386-c4-doced-saved-role-six-before/result.json`. The fixture records
parent-link failures before test-only repair permits safe fixture disposal.

All six native cases pass, with exact fixture bytes and unchanged inputs, in
`build/i386-c2-doced-saved-role-six-green/result.json` (ten commands). Run all cases,
or use --case 0 through --case 5 to isolate one:

```sh
python3 tools/test-i386-doced-saved-role.py build/i386-c2-doced-parent-cross/kernel.img --out build/new-saved-roles
```

The final image is `build/i386-c2-doced-parent-cross/kernel.img`. Its cross-build
and limited 386 audit pass, all 1480 source/build hashes match, and the two
original bootstrap generations pass. Source-matched original state/failure
controls pass in `build/i386-c4-doced-parent-{state,failure}`.

Native regressions pass with unchanged inputs:

- `build/i386-c2-doced-parent-state`: ten commands, all six state masks 255.
- `build/i386-c2-doced-parent-failure`: six commands, both callback masks 31.
- `build/i386-c2-doced-parent-exit`: five commands, callback Exit mask 63.
- `build/i386-c2-doced-parent-form`: eight synchronized form/define commands.
- `build/i386-c2-doced-parent-view-owner`: five edited-owner retirement commands.
- `build/i386-c2-doced-parent-startup`: nine normal 8 MiB checks, 49.15 seconds.

State/failure/Exit runners now use the same additive fixture staging, normal
guest #include and independent post-run byte verification as the owner tests.
Their previous 39/27/27 commands become 10/6/5 without dropping behavioral cases.
The packaging preservation/rejection suite passes on the new image as well.

This qualifies the specified saved-role and original-parent retirement cases
while View is active. Explicit DocDel is now covered by the separate
[deletion contracts](i386-doced-deletion.md). Constructor/admission failures, recovered
cancellation, failures during restoration, late input/scan and precise teardown
heap accounting remain open. It does not qualify arbitrary post-return document
links or complete form/menu/editor/application compatibility.

Explicit deletion through scoped View, including foreign allocation owners,
now has the [Console 98 regression and storage-retention evidence](i386-doced-deletion.md).
Deleter cancellation and cyclic descendant teardown remain unqualified.
