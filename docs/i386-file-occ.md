# Original file occurrence counting

Psalmody's JukeBox uses `FileOcc` from the complete original
`Adam/Opt/Utils/Find.HC`. `tools/test-i386-file-occ.py` compares that service
using two fixed text files. It checks default whole-label/case-insensitive
matching, unrestricted matching, case sensitivity, whole labels, left/right
label boundaries, overlapping matches, no match and a caller already in silent
mode. The expected counts are independently specified as
`5, 9, 7, 3, 8, 6, 3, 0, 5`.

The fixture also requires normal silent-state restoration after every call,
no output document content, the same output document, and unchanged working
directory (mask 4095). It restores its temporary caller state afterward.

* `build/i386-file-occ-original-v1/result.json`: all nine counts and mask 4095
  pass on the pinned original system; inputs unchanged.
* `build/i386-file-occ-native-v1/result.json`: the clamp image preserves the
  original Find source bytes, but its full include rejects PutFileLink at line
  60 before the fixture executes; inputs unchanged.

```
python3 tools/test-i386-file-occ.py --out build/file-occ-original
python3 tools/test-i386-file-occ.py build/IMAGE/kernel.img --out build/file-occ-native
```

The native successful path additionally requires fresh rendered arithmetic,
unchanged preexisting file bytes/attributes/timestamps, only the three declared
fixture additions, and a structurally valid filesystem. Those native behavior
checks have not yet passed. Find replacement, popup wizard, exceptional cleanup,
recursive multi-file matching and full Psalmody/C1–C5 qualification remain open.

The link candidate advances the full original include to `PopUpPickDir` at
line 234 (`build/i386-file-occ-candidate-v1/result.json`, inputs unchanged).
The counting fixture still does not execute. The original chooser provider is
`Adam/DolDoc/DocPopUp.HC`; it builds a FileMgr directory-picker command, passes
the caller to PopUp, and returns the selected allocated name. Porting must
preserve that real popup workflow rather than substituting a result to permit
the Find include.
