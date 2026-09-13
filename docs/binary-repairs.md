# Binary repair provenance

The archived export applied the `TOSZ -ascii` transformation (replace byte
0x1f with 0x20 and remove byte 0x05) to complete files, including binary payloads.
This broke DolDoc binary record lengths, sprites, compiler maps, and autocomplete
indexes. Startup repeatedly printed `Bin Not Found` while loading the maps.

Recovery source: https://templeos.org/Downloads/TempleOS.ISO

SHA-256: `5d0fc944e5d89c155c0fc17c148646715bc1db6fa5750c0b913772cfec19ba26`

The reference RedSea filesystem was extracted and `.Z` files expanded using
this repository's `Linux/TOSZ.CPP`, compiled on Linux, without `-ascii`.
For every file below, applying the exact ASCII transformation to the reference
produced the archived file byte for byte. This establishes the original bytes
without guessing how to reverse a lossy conversion.

For `.HC`, `.DD`, and `.MAP`, only the binary tail starting at the first NUL was
restored, preserving the archive's readable source text. `.DATA` and `.GR` files were
restored in full. The archived kernel and compiler binaries were not replaced.
The repaired data is committed in the fork; builds need no downloads.

Repaired files:

- `Adam/AMouse.HC`
- `Adam/AutoComplete/ACDefs.DATA`
- `Adam/AutoComplete/ACWords.DATA`
- `Apps/KeepAway/KeepAway.HC`
- `Apps/Logic/Logic.HC`
- `Apps/Psalmody/PsalmodyDraw.HC`
- `Apps/Titanium/Titanium.HC`
- `Apps/ToTheFront/TTFInit.HC`
- `Apps/X-Caliber/X-Caliber.HC`
- `Compiler/Compiler.MAP`
- `Demo/AcctExample/PersonalMenu.DD`
- `Demo/AcctExample/TOS/TOSTheme.HC`
- `Demo/Games/BattleLines.HC`
- `Demo/Games/BlackDiamond.HC`
- `Demo/Games/BomberGolf.HC`
- `Demo/Games/CastleFrankenstein.HC`
- `Demo/Games/DunGen.HC`
- `Demo/Games/FlapBat.HC`
- `Demo/Games/FlatTops.HC`
- `Demo/Games/RawHide.HC`
- `Demo/Games/RocketScience.HC`
- `Demo/Games/Stadium/StadiumBG.GR`
- `Demo/Games/Talons.HC`
- `Demo/Games/TheDead.HC`
- `Demo/Games/Varoom.HC`
- `Demo/Games/Wenceslas.HC`
- `Demo/Games/Zing.HC`
- `Demo/Games/ZoneOut.HC`
- `Demo/Graphics/EdSprite.HC`
- `Demo/Graphics/Elephant.HC`
- `Demo/Graphics/Extents.HC`
- `Demo/Graphics/LightTable.HC`
- `Demo/Graphics/Pick.HC`
- `Demo/Graphics/Pick3D.HC`
- `Demo/Graphics/RotateTank.HC`
- `Demo/Graphics/Shadow.HC`
- `Demo/Graphics/SpritePlot.HC`
- `Demo/Graphics/SpritePlot3D.HC`
- `Demo/Graphics/SpriteText.HC`
- `Demo/Graphics/WallPaperFish.HC`
- `Doc/Hash.DD`
- `Doc/HelpIndex.DD`
- `Kernel/Kernel.MAP`
- `PersonalMenu.DD`
