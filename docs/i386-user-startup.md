# Original User startup on native terminals

`HomeSys.HC` now includes `Adam/UserStartUpCore.HC` for its complete original
`UserStartUp` body. Expanding this include and the existing SrvStartUp include
reproduces the pinned original HomeSys bytes exactly. The extraction retains
DocTermNew, original welcome Type, SHOW, WinToTop, WinZBufUpdate and Dir.

Native startup publishes that default in Adam's shared scope. A new User task
loads its native public declarations, resolves UserStartUp through its actual
symbol chain with CallExtStr, and adopts the resulting put document. It keeps
the callback's document, border, menu, attributes and controls. It does not add
a synthetic native heading to that document. The original task owns these
allocations; normal owner retirement and heap teardown reclaim them. A custom
startup inherited by an explicitly parented Spawn(UserCmdLine) remains callable.
The bootstrap root console and its minimal welcome remain a separate startup
path; this does not launch HomeSys's two-terminal desktop orchestration.

The default document title define must also be shared. Previously
ConsoleDocumentStart defined DD_OS_NAME_VERSION only in the initial console's
private scope. A new User could not inherit it, and original DocRecalc replaced
the title tag with an empty string. StartOS now runs the original DefinePrint
format in Adam's scope before publishing the default startup functions. Root
private/custom definitions still follow ordinary hash-table lookup.

Public Dir now routes mapped and other media through the existing complete
original directory listing implementation. The removed shortcut listed C:/
for an omitted argument, did not implement file masks, and bypassed stdout
hooks. The shared implementation supplies actual cwd/masks, metadata, directory
macros, file links and the ordinary string/character output chain. Internal
picker enumeration retains its separate listing service.

Evidence before the shared-define fix:

- `user-constructor-native-before-v1` returns169/255 on the previous image.
- `user-constructor-native-v1` rejects boot because a newly added nine-character
  exception tag exceeds HolyC's eight-byte character constant. The corrected
  tag and subsequent build are separate; this is not a User runtime result.
- `user-constructor-native-v2` reaches191/255: constructor roles now pass but
  welcome bytes fail. `user-welcome-diagnostic-v1` records a missing inherited
  define and the exact empty-title document alongside the original219-byte
  welcome file.
- `user-constructor-current-original-v1` passes255 on the current classic
  rebuild, confirming the extracted original startup remains intact.
- `user-hook-original-v2` and `user-hook-native-v3` pass63 for one local callback
  invocation in the actual child, terminal roles and controls, the exact20-byte
  custom prefix without a default/native heading, and successful Kill.
- `user-startup-scroll-original-v1` and `user-startup-scroll-native-v3` pass the
  original nine root wheel/cursor values and4095 for three User create/reuse/
  kill cycles with exact caller data/code heap usage. This does not measure
  every kernel pool, callback lifetime or resource.

`tools/test-i386-dir-output.py` captures both stdout strings and characters
through task-filtered KeyDev hooks. It checks every emitted byte for default,
full, missing-mask and file-mask listings in an explicitly seeded, read-only
directory, including dot entries, links, macros, dates and sizes. Its independent
formatting model binds to exported live FilesFind metadata: drive letters,
directory dates and physical clusters differ between the two filesystem images.
It does not rewrite, filter or reorder the actual output. The empty output is
also directly byte-equal across systems. Caller cwd/put document/timezone and
fixture presence must restore; the native volume must remain unchanged and a
fresh42 must render. The old default returns26 instead of3 and masks return-1
instead of0/1; its stdout bypass is retained as a strict failure at
`dir-output-native-before-v2`. Original `dir-output-original-v8` and native
`dir-output-native-v4` pass the complete model and counts3/3/0/1.

Earlier directory prototypes retain explicit corrections: FileWrite returns a
starting cluster rather than byte count; directory deletion is not included in
the deleted-file count; and the default native boot does not configure the
original B: RAM drive. A malformed metadata export used StrPrint's returned
pointer as a length. Its13GB diagnostic dump is retained as a12MB lossless
zstd archive with a decompressed SHA-256 receipt. The corrected host rejects
exports above16KiB. None of these prototypes qualifies directory behavior.

Console ABI271 versions the changed User startup behavior. Remaining original
prompt/input, root/desktop orchestration, full menu/right-click actions, raster,
all resources, other document defines and native self-hosting remain open.
Inventory qualification stays2/686; no whole C1-C5 milestone is claimed here.

The final full-profile image is `build/i386-user-startup-cross-v5/kernel.img`.
It pins1861 sources and26 build helpers; its source-matching classic rebuild
passes two generations. Only Kernel and ConsoleRuntime differ from ABI270;
the bare kernel remains458680 bytes and the386 instruction audit passes.
These classic bootstrap generations do not establish native self-hosting.

A new document terminal stores its incremental text projection in4800 nine-byte
cells (43200 bytes), rather than eagerly allocating153600 planar bytes already
represented by its managed document. Each cell captures the actual eight glyph
rows at write time, including underline and font changes, plus color attributes.
Scrolling preserves cleared pixels even when the space glyph is nonempty.
Legacy/raw consumers materialize the identical raster on demand; both buffers
are released on retirement and unpublished-construction failure.

`user-text-projection-vga-v3` compares every planar byte against the prior direct
raster through6000 writes, scrolling, controls, colors, underline, font switches
and later font-data mutation, then1000 additional writes after materialization.
The existing independent VGA oracle still checks all307200 displayed pixels.
`user-legacy-native-v3` takes an actual User into retained DocEd, checks614400
pixels across before/after-save screens, saves exact abc plus cursor bytes,
restores original welcome/document roles and kills the child. All1890 prior
files remain intact, and fresh42 passes. This is a native legacy transition
regression; original editor UI parity remains open.

The unchanged stock startup fixture passes255 at64MiB
(`user-constructor-native-v4`) and8MiB (`user-constructor-native-8m-v2`). Before
the compact buffer, the same complete startup failed at8MiB allocating153600
bytes. The native physical main-heap sampler performs two warm and three
measured actual User create/Kill cycles. `user-main-heap-native-v3` restores
both used bytes and allocation counts exactly in every trial. Live deltas are
348232 bytes each, versus458344 in `user-main-heap-before-cells-v1`:110112
bytes less per live User. These are live snapshots, not peak measurements or
proof of all resource lifetimes. Caller data/code heaps also remain stable.

Final isolated8MiB KVM486,-fpu startup is54.576s with live WinMgr and exact
welcome/fresh42 pixels (`user-startup-startup-8m-v2`). No other QEMU was running
at invocation. This establishes only the current60-second baseline subgate.

Both final MsgLoop variants retain strict saved-document failures at
`msg-loop-user-startup-native-v1` and `msg-loop-user-startup-shift-native-v1`.
Their complete18/19-record chronological streams match the pinned originals,
and restoration is7. A repeated original run (`msg-loop-repeat-original-v1`)
also produces a different saved document with an identical stream. Persistent
wheel cursor positioning and render/output interleaving require a controlled
schedule before attributing that difference. The strict failures remain; no
entries are removed, sorted or normalized to obtain qualification.

`build/user-startup-audit-v1/verify.py` independently rechecks current source
and helper pins, original HomeSys expansion, raw directory bytes against the
metadata model, raw heap recovery, stream equality and failure receipts.
Historical bootstrap binaries are found by their exact hashes in preserved
rebuilds; historical source pins and delivered VGA fixtures are checked inside
the retained compiler ISOs. Full C1-C5 remain open,2/686.
