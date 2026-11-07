# Directory entry lookup

FileMgr uses `Cd2DirEntry(head,old_cur_dir)` to find its initial tree entry.
The original implementation in Kernel/BlkDev/DskStrA.HC recursively follows
matching prefixes, checks slash boundaries to distinguish sibling names, and
returns the exact entry pointer. It does not normalize case or trailing slashes.

`tools/test-i386-cd-dir-entry.py` exercises the original public function against
a synthetic linked tree. In `build/i386-cd-dir-entry-original-v1`, all twelve
independent checks pass: null head; exact root and sibling root; direct, nested
and leaf entries; similarly prefixed siblings; missing descendants and prefixes;
case-sensitive failure; trailing-slash failure; and preservation of the checked
links and leaf name. Inputs remain unchanged and were independently rehashed.

The same fixture on interface 231 rejects `Cd2DirEntry` at line 13 before any
checks run (`build/i386-cd-dir-entry-native-baseline-v1`, unchanged inputs and
independent pin audit). This matches the full FileMgr rejection at line 592.
The native binding and shared original implementation remain to be added.
These synthetic lookup cases do not qualify the complete filesystem tree,
chooser interaction, FileMgr or C1–C5.
