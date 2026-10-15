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
specified points. Saved put/display/border owners, explicit DocDel of an active
document, recovered cancellation with a live caller, restoration interrupted by
another exception, late input/data-scan failures, allocation failures and precise
teardown heap accounting remain open. Retiring while manager frames borrow a
temporary border also needs its own gate. TaskValidate becoming false is not
proof that every backing allocation has been reclaimed. C1–C5 remain incomplete.
