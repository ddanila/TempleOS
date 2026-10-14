# Packed original sprites in the editor

The editor no longer uses NativeDocSpriteDraw's separate padded subset renderer.
It validates the record storage and calls the existing original Sprite3 renderer.
The original packed color/rectangle/end sequence is twenty bytes (2 + 17 + 1),
not the old fixture's twenty-three. Point records are nine bytes, not twelve.
The rectangle uses the original polygon rasterizer's inclusive endpoints.

## Failing behavior and implementation

```
python3 tools/test-i386-doc-packed-sprite-editor.py IMAGE --out build/FRESH-editor
```

The test constructs the original typed records, saves the DolDoc file, reloads
it and verifies the twenty-byte binary record. It opens the document in DocEd
and compares the entire VGA frame with an independent font/palette expectation.
The blue rectangle overlaps an A glyph, including its original boundary pixels.
On the preceding image, storage round-trip passes but all 65 expected blue pixels
are absent (`build/i386-c4-packed-sprite-editor-red/result.json` and its initial
frame). The old decoder rejects the packed rectangle as too short.

NativeDocSpriteDraw now calls SpriteDataValidateCore then Sprite3, removing the
private point/line/rectangle rasterizers and their padded record assumptions.
The existing DocSpriteRenderCheck fixture uses original packed records, with
endpoints 15/7 to preserve its established visible 16x8 rectangle. Its size/result
is now twenty; the existing harness checks that size. Invalid record storage is
skipped before the renderer is called.

The corrected image passes all twelve commands and the full-frame packed-sprite
editor check (`build/i386-c4-packed-sprite-editor-green/result.json`). The legacy
`document-sprites` group also passes with unchanged visible pixels
(`build/i386-c4-packed-sprite-legacy/result.json`).

## Record bounds

SpriteDataValidateCore uses the original record-size table and packed types.
It checks fixed headers, exact termination, bounded strings and variable payloads,
signed/oversized counts, bitmap dimensions and mesh vertex indices. Count-size
arithmetic is checked against the remaining storage before it advances.
It covers the original record types rather than imposing a color/rectangle-only
format. This is structural validation, not a proof of every primitive's geometry
or resource behavior.

```
python3 tools/test-i386-sprite-data-validate-reference.py --out build/FRESH-reference
python3 tools/test-i386-sprite-data-validate.py IMAGE --out build/FRESH-native
```

Both original-layout and native component runs pass eighteen boundary cases:
`build/i386-c4-sprite-validate-reference/result.json` and
`build/i386-c4-sprite-validate-native/result.json`. The original-layout run loads
the current validation core into the pinned original; it does not claim the
original OS supplied this validation policy. The native check is explicitly
included test support, not resident startup diagnostics.

Bootstrap rebuild, cross-build and the 386 boot audit pass
(`build/i386-c4-packed-sprite-cross`). Startup passes at 8 MiB in 45.78 seconds
with no build-provider loading (`build/i386-c4-packed-sprite-startup/result.json`).

## Remaining qualification

The editor still has its separate text/layout path. The successful rectangle
case does not establish every sprite, editing operation, scroll/focus behavior,
callback exception or allocation-failure path. Original DocRecalc/compositor
qualification remains separate. Scheduled refresh and automatic document stdout
are still required for desktop/GetStr integration.
