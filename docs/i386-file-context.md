# Native drive contexts and compiler source loading

`I386FileReadAt` connects explicit path construction to the decoded RedSea loader.
A borrowed `CI386FileVolumes` table maps the 26 drive letters to mounted native
RedSea volumes. The caller supplies its `CFilePathContext`; no global current
folder is changed. Lowercase drive letters select the corresponding uppercase
slot, while the constructed name retains its original case. Boot/home prefixes
are resolved by the shared path rules before volume selection.

The reader constructs an absolute filename, selects its volume and searches from
that volume's root using the existing local exact/alternate and ancestor order.
It does not add a default extension. Unbound/non-letter drives and paths without
an absolute drive/root prefix fail before volume I/O. Existing lookup, read and
archive failures stop the operation without trying a different drive.

Success returns decoded bytes in one owned, NUL-terminated allocation, with
optional byte count and resolved-file attributes. An optional name output retains
a second allocation containing the requested absolute name. This is not the
resolved alternate or ancestor path; it matches the distinction needed by the
original compiler's source records. Failure leaves every optional output unchanged
and reclaims temporary absolute names and reader allocations. Free returned buffers
through the same heap; output locations must be live and distinct from inputs.

## Compiler bridge

`I386LexIncludeFile` applies the original compiler sequence: add a default HC.Z
extension, construct an absolute name, read that name, then transfer the decoded
source to an owned lexer child using I386LexIncludeTake. The first absolute name
is copied into the source record. As in the original Lex/FileRead call chain,
the reader normalizes that name again. This matters when noncanonical context
strings produce repeated separators; the fixture makes the distinction observable.

File records, copied names and loaded buffers have the existing include-stack
ownership. Parent character replay and EOF return use the shared lexer machinery.
Failure before publication leaves the compiler control unchanged and frees all
new buffers. The source is transferred only after the record/name allocations
succeed. Empty sources are valid. Document/prompt/echo modes remain unsupported
by this raw-file bridge and are rejected before loading.

Both functions currently require quiescent volumes, exclusive channel access and
interrupts disabled. They reject enabled IF before I/O and preserve IF. Paths,
volume bindings and compiler state must remain stable throughout the operation;
these functions neither acquire scheduler locks nor yield. This is a bootstrap
integration contract, not permission to perform long masked reads in the final
interactive system.

## Verification and remaining work

The `--redsea-read` fixture mounts two distinct volumes on the test disk and checks
current, explicit, lowercase, boot and home drive routing with distinct source
contents. It checks inherited/compressed and empty files, optional name ownership,
missing/unbound/malformed requests, metadata preservation and enabled-IF rejection.
Existing codec, alternate/ancestor, malformed-topology and whole-disk immutability
checks remain enabled.

Compiler-input tests push nested plain/compressed disk sources, compare every
character, verify both parent replays and 66 input lines, and reclaim both children
at EOF. Missing/corrupt/unbound input and a real partial ATA read preserve a byte
snapshot of the active compiler control and its heap baseline. Another case checks
the two normalization steps while retaining the first name for source metadata.
Eighty-six small heap arenas span failure and success, with complete reclamation.
These tests operate directly on the include service and raw reader; they do not
claim that the native lexer dispatches include directives or that it runs a parser.

Native integration checks and executable instruction audits pass. Both x64
rebuild/reboot generations pass, and the unchanged standalone image passes its
boot regression.

Commands:

```
python3 tools/test-rebuild.py
python3 tools/test-i386.py --redsea-read
python3 tools/build-i386-kernel.py --test
```

The integration fixture uses a 256 KiB loader ending at 0x50000, a separate
128 KiB heap at 0x50000–0x70000, and small test arenas at 0x71000. The largest small
arena ends below 0x82100, clear of the runner stack. These are test placements;
the standalone bootstrap remains 383496 bytes and does not yet link these services.

Remaining work includes current-task/public drive binding, resident-file caching,
public FileRead errors/exception behavior, scheduler-aware ATA ownership, resident
include-service binding and full compiler-control construction/destruction.
The fixed borrowed volume table is an integration input for public wrappers, not
a replacement application API or a new device framework. Resident parser/JIT,
DolDoc, strict 386SX/DX verification and native self-hosting remain required.

Native directive dispatch now accepts this bridge through I386LexFileInclude and
an explicit service context. See `i386-lex-includes.md` for its compatibility tests,
callback contract and remaining resident-module integration.

The file bridge is now packaged in retained FileRuntime and bound to the retained
compiler's include dispatcher during native boot. See `i386-file-runtime.md` for
the connected disk tests and the remaining task/interrupt ownership restrictions.
