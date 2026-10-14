# Original document frame composition

The ordering concern in the earlier renderer checkpoint is resolved by inspecting
the original GrUpdateScrn loop in Adam/Gr/GrScrn.HC. It performs text background
and foreground composition, then GrUpdateTasks, then persistent graphics and the
final callback. GrUpdateTaskWin calls DocUpdateTaskDocs, which invokes DocRecalc
TO_SCRN. Thus document text cells produced during task drawing appear in the
following refresh; sprites draw during the current refresh. GraphicsFrameCore
already follows that ordering. This is not a compositor defect to fix by calling
DocRecalc twice.

## Original oracle

```
python3 tools/test-i386-doc-compose-reference.py --out build/FRESH-reference
```

`build/i386-c1-doc-compose-reference-final/result.json` passes. The fixture uses
the original GrUpdateTextBG/FG and DocRecalc on two successive private frames.
It masks interrupts during the temporary global-frame swap, then restores the
original frame/cell pointers, task attribute and interrupt flags. The private
frame is marked screen/on-top to isolate the drawing contract from window
occlusion; this does not qualify visibility policy.

The initial text cell is P. A tag callback yields A on its first invocation and
B on its second. A blue rectangle sprite overlaps the glyph. First-frame packed
pixels show P beneath the current sprite; second-frame pixels show A beneath the
sprite. Both 24x8 regions match independent font/color expectations. Metadata
is exactly `[1,65,2,66,2,17]`: callback counts and newly written cell characters,
then original sizes of CSpriteColor and CSpritePtPt.

The records are packed: color is two bytes, rectangle seventeen. The fixture
constructs them through their declared types. Initial hand-padded records failed
to draw as intended; typed records exposed the original polygon rectangle's
inclusive x/y boundary behavior. The final independent expectation includes
those boundaries and checks the first pixel beyond the rectangle as well.

## Native frame check

```
python3 tools/test-i386-doc-compose-frame.py IMAGE --out build/FRESH-native
python3 tools/test-i386-doc-compose-frame.py IMAGE --ram-mib 8 --out build/FRESH-8m
```

The fixture uses NativeGraphicsPresent with a drawing callback that calls the
original DocRecalc once. It asserts the original packed record sizes, checks two
full 640x480 VGA frames using independent font/palette/sprite expectations, then
requires two tag invocations and the newly stored B cell. It restores the display
document, task attribute and console surface and completes arithmetic afterwards.

Both 64 MiB and 8 MiB runs pass all sixteen commands:
`build/i386-c4-doc-compose-frame-typed/result.json` and
`build/i386-c4-doc-compose-frame-8m/result.json`. No OS implementation changes
were needed to match this original composition contract.

## Remaining work

Integrate scheduled task/document refresh with stdout instead of forcing a
second document evaluation to refresh cells immediately. Keep the original
text/task/sprite/persistent/final ordering and test dynamic evaluation frequency,
focus, cancellation, error cleanup and resource use.

A separate existing editor path remains incompatible: NativeDocSpriteDraw in
Kernel/I386/DocumentRuntime.HC assumes padded point/rectangle records (12/20 bytes),
and DocSpriteRenderCheck builds a 23-byte color/rectangle/end fixture. Original
packed color/rectangle/end data is twenty bytes. Its custom subset rendering is
not qualified by the passing original DocRecalc/compositor tests. Replace that
path with original sprite behavior and qualify it with packed binary documents;
do not treat the earlier custom fixture as original sprite-format parity.

These tests cover one static rectangle and one dynamic text callback. Arbitrary
sprites, persistent/final overlays with document output, cursor, scrolling,
window occlusion, focus and automatic stdout remain open.
