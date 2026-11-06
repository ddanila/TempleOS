# Public file links

The full original `Adam/Opt/Utils/Find.HC` requires `PutFileLink` at line 60.
Loading it on the clamp candidate fails there
(`build/i386-psalmody-find-probe-v1/result.json`), preventing the `FileOcc`
provider required by Psalmody's JukeBox loader from being defined.

`tools/test-i386-file-links.py` checks null input and seven serialized links:
explicit source and plain-text targets, their line-number forms, sprite and
sprite-line targets, and a default absolute path resolved from the boot root.
The host builds the expected DolDoc bytes independently. The only per-platform
expected difference is the boot drive (T for the original ISO, C for native).
The fixture restores the caller's output document, directory and raw flag.

* `build/i386-file-links-original-v1/result.json`: exact 254-byte document passes;
  all execution inputs unchanged.
* `build/i386-file-links-native-v1/result.json`: first PutFileLink call is rejected
  while compiling the fixture; all execution inputs unchanged.

```
python3 tools/test-i386-file-links.py --out build/file-links-original
python3 tools/test-i386-file-links.py build/IMAGE/kernel.img --out build/file-links-native
```

The plain source candidate `build/i386-public-tables-candidate-v4/source` exports
the existing shared `Kernel/BlkDev/DirectoryLinksCore.HC` implementation and adds
its exact four-argument public declaration, including defaults. Console
interface 216 separates this binding set from previous images. The function
body is unchanged. Validation is in progress; these core changes are not yet
applied to main because the concurrent C5 build pins its inputs.

Raw-screen output, following links, directory links, Find replacement/dialog
workflows and whole Psalmody/C1–C5 qualification remain open.
