# DocEd restoration interrupted by a window-control exception

The shared fixture is
`tests/guest/i386-doced-restore-reference/DocEdRestore.HC`. It attaches a real
CCtrl to the caller's control ring and uses public DocEd with WIN_MAX, SIZE_MIN,
DONT_SHOW and DONT_WINMGR_SYNC. An Escape message completes View. The control
throws `Restore` exactly once when the caller's original document roles have
been restored and the selected geometry axis returns to its saved value.
It is not a replacement WinHorz/WinVert or synthetic task.

The original system returns **[127, 255]**. Horizontal geometry is assigned
before its control callback runs; if that callback throws, vertical restoration
is skipped. A vertical callback throws after both coordinates have been assigned.
The native oracle preserves this original observable behavior rather than
silently requiring completion of vertical restoration after a horizontal error.

Bits require the original exception identity (1), restored put/display/border
roles (2), title/attribute restoration (4), released edited-document lock (8),
exact caller data-heap recovery (16), preserved interrupt state and released task
lock (32), actual restoration callback entry (64), and both geometry axes restored
(128). Both cases then remove the real control, delete the edited document and
restore the fixture's incoming geometry. A stale native editor lease would reject
that deletion. The native runner also checks continued arithmetic, exact packaged
fixture bytes and unchanged inputs on a writable copy of the base image.

Original evidence: `build/i386-c4-doced-restore-reference/result.json`, using the
current passing two-generation x64 rebuild. Native evidence is
`build/i386-c2-doced-restore-compatible/result.json`: six commands pass with
exact fixture readback and unchanged inputs. Both systems return [127,255].
Runtime remains Console 99 / Memory 26; no behavioral change was needed.

This qualifies geometry-control failure during ordinary restoration. It does
not cover recovered cancellation during restoration's lock transition, a
throwing border destructor, constructor/admission failure, late input/scan
failure, or arbitrary cyclic ownership. Those remain distinct gates.
