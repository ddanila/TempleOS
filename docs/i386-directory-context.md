# Original directory-context contracts

Full original DocPutKey changes the document's directory context through
DirContextDel/DirContextNew. Their complete source is
Kernel/BlkDev/DskDirContext.HC, and CDirContext is declared in Kernel/KernelA.HH.
The native public binding is still missing. No runtime directory-context port
or completed desktop milestone is claimed by this test-first checkpoint.

The shared fixture tests/guest/i386-directory-context-reference/Context.HC
calls the actual public routines and observes their returned context, real
Fs directory/drive fields, caller document roles and heap. It does not implement
a substitute path parser. The original uses writable RAM drive B; the native
runner selects C. Both use /Probe/DirContext with real A/Nested and B directories.
This profile mapping is explicit; it is not cross-drive restoration coverage.

| Case | Expected behavior |
| --- | --- |
| Filename mask | Retain the current directory and mask note.HC. |
| Relative directory | Enter A; retain *.HC. |
| Whitespace | Trim leading/trailing spaces; enter A and retain note.HC. |
| Multiple masks | Enter A; retain *.HC;*.HH. |
| Directory make_mask | Recognize existing A as a directory; enter it and use *. |
| Empty make_mask | Stay in the caller directory; use *. |
| no_mask | Enter A and return an empty mask. |
| make_dirs | Create/enter Made/Deep; retain *.HC. |
| restore FALSE | Deletion keeps A as current; fixture restores the original directory only after observing that behavior. |
| Nested contexts | Enter A/Nested, restore A on inner deletion and the original directory on outer deletion. |
| Failed path | Enter a valid A prefix, fail at Missing/Deep, return NULL and restore the original caller directory. |
| Null deletion | No directory/drive/role/heap change. |

For non-null contexts, assertions include exact old_dir/mask strings and
old_dv/dv identity. All cases check active/final paths, drive identity, unchanged
DocPut/DocDisplay/DocBorder and exact caller heap recovery after fixture cleanup.
No context-field assertion is made for a failed creation/null deletion because
there is no returned object. Cleanup of restore-FALSE state occurs after its
observable behavior is measured. Filesystem directories intentionally remain
in the disposable guest image.

build/i386-c4-directory-context-reference passes twelve masks of 63. The stronger
partial-progress failure path in
build/i386-c4-directory-context-partial-reference also passes twelve masks, with
unchanged inputs. Both execute on the qualified current original x64 rebuild.

build/i386-c2-directory-context-partial-prerequisite-red rejects the missing
DirContextNew binding with Invalid lval at its first preflight function. The
fixture and setup never run; this proves the API prerequisite remains missing,
not that any native directory-context behavior has passed or failed.

Reproduce with fresh output directories:

```sh
python3 tools/test-i386-directory-context-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-directory-context.py build/i386-c2-editor-replace-navigation-cross/kernel.img --out build/NEW-native
```

The full native Console build has now failed; its independent diagnostic replay
preserves its embedded source image (see [fault evidence](i386-native-console-fault.md)).
Independent candidates can use a separate output directory. Share the canonical context
type and complete original routines, and supply actual drive, string and
silencing services. Do not copy a private prefix layout or replace these with
a current-directory string shortcut. Repeat the same contracts on the port.
Cross-drive/removable-media behavior, initialization-in-progress restoration,
invalid drives, allocation failure, exceptions, cancellation and cross-task
ownership require separate contracts. Full original input and C1–C5 remain open.

## Native drive-state prerequisites found in source review

Exposing the string utilities removes only one dependency family. Before
integrating the unchanged context routines, resolve these actual representation
boundaries:

* Native `CDrv` has its canonical complete record, but `CBlkDev` is only forward
  declared in that header. `BlockDevTypes.HH` currently supplies device-kind
  constants, not the complete block-device record/flags. Context deletion reads
  `old_dv->bd->flags`, so a private shortened record would be unsafe.
* `I386TaskFilesDrive` constructs stable public drive identities from mounted
  RedSea volumes, but does not associate a real `CBlkDev` with them. Supply
  accurate backing-device identity and state before relying on that field.
* `I386TaskFilesNew` embeds the directory string immediately after its state
  allocation. Canonical context deletion's initialization-in-progress branch
  frees/replaces `Fs->cur_dir` directly. That branch cannot safely use an interior
  pointer owned by the task file-state allocation. Resolve ownership and keep
  the public directory/drive fields synchronized with internal file operations.
* The original `Drv` changes device state and resets the directory, while native
  file operations use `CI386TaskFiles` and its borrow/set/release protocol. Test
  public drive changes, alias resolution, restoration and initialization/error
  paths against the original before wiring the complete routines.

These are source-review findings, not runtime qualification. Keep the existing
same-drive context cases and add drive/device and exceptional ownership gates;
do not make directory restoration a string-only shim or remove original
initialization branches to avoid these prerequisites.
