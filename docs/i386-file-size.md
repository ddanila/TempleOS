# File size and flag parsing

The complete original Size1/Size functions, ScanFlags function and
ST_FILE_UTIL_FLAGS initializer are now shared units. The original ADskB, StrB
and KDefine wrappers include them in place. The native console retains those
bodies and publishes Size and ScanFlags through public headers. Console ABI 208
has 579 bindings. The full original flag list is installed in the kernel root
scope during console initialization, before public startup and child use.

No size traversal or flag-parser branch was replaced. Size retains stored and
expanded compressed sizes, single-file and directory traversal, filters,
recursive accumulation, per-entry user_data, rounding and tree cleanup. ScanFlags
retains its arbitrary-width bitfield, list matching, partial application and
ScanFlag exceptions. The supplied flag list retains all original ordinals.

Two details follow the original behavior:

- With expansion and rounding enabled together, rounding uses the stored entry
  size, overriding the expanded size read from its compression header.
- Non-recursive RedSea wildcard enumeration includes the base directory's dot
  entry; its size contributes to Size. Default recursive traversal excludes it.

The paired contract passes fourteen size cases on rebuilt original and native
systems (`build/i386-file-size-reference-v4/result.json` and
`build/i386-file-size-native-v1/result.json`). It covers stored/expanded
compression, empty and missing files, recursion, file-only filtering, rounding,
parent paths, directory records and a 4 GiB rounding quantum. Every case retains
the current directory and exactly recovers the warmed caller heap. The native
run keeps the real window manager active, matches every framebuffer checkpoint,
and executes an arithmetic command afterward. Both runs keep their inputs
unchanged.

The same fixture passes flag-parser mask 31 on both systems. It exercises 70
flags, setting and clearing across the 64-bit boundary, ignored leading text,
spaces, null source, unknown names, partial application before an exception,
empty-token rejection, trailing individual signs and exact heap recovery.

Two original rebuild generations pass (`build/file-size-rebuild-v2.log`). The
native image passes the 386 instruction audit and the source audit matches
1,257 packaged source/documentation files
(`build/i386-file-size-cross-v2/source-audit.json`). An additional audit verifies
all three shared units and their original wrappers, including Adam/ABlkDev
outside that audit's directory set, and proves body equality against the prior
original definitions (`build/i386-file-size-cross-v2/media-source-audit.json`).

Earlier fixtures remain failed attempts: v1 assumed FileWrite returned a byte
count although the original returns a cluster, v2 omitted the non-recursive dot
entry, and v3 left an empty flag token's original exception uncaught. The first
native build also identified the missing ScanFlags dependency; it is now the
complete original parser, with its real initializer.

The unchanged real-service MakeAC load now reaches missing HashTableSize2 at
ACInit.HC line 166 (`build/i386-file-size-autocomplete-v1/result.json`, unchanged
input pins). No autocomplete task is explicitly activated. Hash accounting must
retain its complete class/function/global/debug/list branches when integrated;
a generic-entry-only substitute would not provide the original API.

FAT-specific size behavior, I/O failure cleanup, arbitrary recursion depth,
full file utilities, autocomplete initialization/suggestions, the existing
8 MiB resource gates and C1-C5 remain unqualified.
