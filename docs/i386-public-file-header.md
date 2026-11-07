# Repeated public file-header inclusion

`Kernel/I386/PublicFiles.HH` ended its include guard before declarations for
`PopUpPickDir`, `PopUpPickFile`, `CopyTree`, `DelTree` and `Cd2DirEntry`.
Re-including it in a scope that already owned those declarations rejected
native symbol publication with exception zero and no compiler diagnostic.
The closing guard now follows all declarations.

`tools/test-i386-public-file-header.py IMAGE --out NEW_DIRECTORY` saves the
five existing function metadata pointers, includes the header twice, and
requires the same pointers afterward. It also calls `DirCur` and checks actual
arithmetic pixels. This tests include idempotence, not the five functions'
complete workflows.

- `build/i386-public-file-header-baseline-v1/result.json`: the old handoff-v2
  image rejects the first repeated inclusion, before the final mask check.
- `build/i386-public-file-header-native-v1/result.json`: the corrected
  command-prompt cross-v4 image passes mask 63 and arithmetic. Its independent
  terminal audit verifies all input hashes, normal startup without input
  rejection, exact fixture bytes, unchanged original file tuples and volume
  integrity.

The full shared-library startup also reaches normal operation with this fix.
An earlier staged diagnostic independently localized the rejection to the
file header after the other public headers had been accepted. Removing the
library's `MemSet` did not change the failure; that diagnostic hypothesis was
rejected. No public ABI changed and no C1–C5 milestone is closed by this fix.
