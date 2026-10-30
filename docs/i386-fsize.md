# Original file-size accessor

ConsoleRuntime 137 publishes the complete original `FSize` function. The
original body is byte-identical in `Kernel/BlkDev/CFileSizeCore.HC`, shared
by `DskCFile.HC` and the native provider. It returns zero for NULL and otherwise
returns the `CFile.de.size` field without mutation; this does not implement file
opening, reading, writing, or block-device initialization.

The pinned-original contract passes mask 15 with unchanged inputs in
`build/i386-fsize-reference`. It checks NULL, zero, full-width and negative
sizes and preservation of other fields. Both original rebuild generations pass;
the cross-build and 386 audit pass with 1540 source and 24 build-input hashes
unchanged in `build/i386-fsize-cross`. The 64 MiB native contract passes mask 15
and all three commands with unchanged inputs in `build/i386-fsize-native`. Its
63.917978-second startup observation was concurrent and is not a timing gate.
The 8 MiB functional check also passes all three commands and mask 15 with
unchanged inputs in `build/i386-fsize-native-8m`; its 63.973494-second startup
was concurrent. Isolated resource gates remain open.

```sh
python3 tools/test-i386-fsize.py --out ORIGINAL
python3 tools/test-i386-fsize.py IMAGE --out NATIVE
```
