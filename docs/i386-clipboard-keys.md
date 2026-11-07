# Clipboard keyboard dispatch

Native DocPutKey now maps the original clipboard bindings to the existing
complete ClipCopy, ClipCut and ClipPaste implementations: Ctrl-C/X/V,
Ctrl-Insert, Shift-Insert and Shift-Delete. Shifted Ctrl-C/X/V, combined
Ctrl-Shift-Insert and Ctrl-Shift-Delete are consumed without clipboard actions,
as in the original. Alt-modified keys bypass this clipboard dispatch.
Descriptions are set inside DocPutKey, preserving its KeyDescSet caller identity.
The user callback still runs first, and the existing undo capture and document
lock/exception handling enclose dispatch. No public ABI or interface version
changes, and FileMgr itself remains unchanged.

The focused fixture covers nineteen cases: four copy/cut/paste binding pairs,
six modifier guards, six key descriptions, incoming document/clipboard locks,
callback interception and copying an empty selection over a seeded clipboard.
Each case checks exact source/target/clipboard text, selection, locks,
descriptions/callback count, caller document roles and resource counters.
The separate FileMgr tests exercise actual hardware keys and normal scheduling.

## Resource oracle development

Original v1 passes all functional observations but fails the assumption that
aggregate Adam heap counts remain fixed while DocPutKey yields. V2 exports
exact caller/root deltas. V3 warms lazy layout state and preserves/disables
the caller's interrupt flag; v4 additionally uses a one-CPU reference guest.
Those controls retain the root counter changes. Source inspection identifies
the explicit trailing Yield in original DocPutKey, controlled by
DOCF_DONT_SWAP_OUT. Disabling interrupts alone does not suppress cooperative
yield. The earlier fixtures/results remain preserved, including their failed
resource expectations. The native baseline also fails the functional clipboard
and key-description checks, independently of the original counter issue.

The reusable Guest helper now accepts reference_cpus=1 or 2, defaulting to its
existing two-CPU original configuration. Only this synchronous resource test
selects one CPU. The final fixture warms lazy layout state, uses the original
DOCF_DONT_SWAP_OUT flag on both test documents, and temporarily disables local
interrupts while measuring. It restores the incoming flags. Original v5 now
passes all nineteen masks of 255 and both nineteen-element zero-delta arrays.
The resource assertion was not relaxed: controlling cooperative Yield makes
the original exact counters pass. These are synchronous single-CPU resource
checks; they do not qualify concurrent clipboard access or scheduling parity.

## Build evidence

Both original bootstrap generations pass in
build/rebuild-clipboard-keys-v1-verified. The full-content cross-build
build/i386-clipboard-keys-cross-v1 passes the 386 instruction audit (96 BIOS,
332 protected-mode instructions). Its post-export audit matches all 1,736
production source hashes to the bootstrap. Runtime results are recorded below. These are partial C2/C4 checks,
not complete DocPutKey, clipboard, FileMgr or C1–C5 qualification.

The final original-v5 and native-v2 runs have byte-identical nineteen masks
of 255 and nineteen zero deltas for each heap. Native-v2 also passes console
arithmetic and filesystem preservation. Native baseline-v3 fails the expected
copy/cut/paste, empty-selection and description cases with zero heap deltas,
so functional failures are distinct from the reference resource-oracle issue.
Terminal audits independently reverify every pinned input and compare exported
rows directly to original-v5. Earlier native-v1 already passes with normal
document flags, but the final paired comparison uses the identical final fixture.

The retained native DocPutKey does not yet implement the original trailing
cooperative Yield. This change restores clipboard dispatch, not scheduling
parity for the complete key routine. Normal scheduled FileMgr workflows are
verified separately. Data-field paste, failure injection, concurrent clipboard
use and broader input behavior remain open as described in i386-clipboard.md.

Normal 8 MiB startup reaches DONE and passes all 307,200 welcome pixels in
build/i386-clipboard-keys-cross-v1/welcome8. This concurrent run establishes
functional startup, not the isolated 60-second timing gate. The 16 MiB startup diagnostic also passes both program, code-heap ownership
and file-break cleanup phases, reaches DONE, and matches all 307,200 welcome
pixels; see diagnostic16-audit.json. Both FileMgr copy/paste/reboot sessions
pass their complete drivers and independent post-reboot audits; see
i386-filemgr-clipboard.md. The larger enclosing interactive suite and isolated
startup timing remain separate gates.
