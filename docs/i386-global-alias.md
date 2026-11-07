# Completed extern-global publication

The canonical type-table probe was rejected before its constructor ran. Splitting
the source showed that class factories published, while the table declaration
input returned false with no compiler error or exception. A small aggregate
reproducer executed and exported correct initialized fields, then failed when
its completed declarations were published.

The shared global parser preserves a completed earlier extern as a non-owning
alias: its unresolved type flag remains, its alias flag is set, and its data
pointer refers to the later definition. Native publication rejected every global
with that unresolved flag. FrontendPublish now accepts this specific alias only
when the same input contains a same-named normal definition with the same data
pointer and tracked ownership of both its metadata and storage. All other global,
type, allocation and transfer checks still apply. The definition retains storage;
the alias does not claim a second ownership record.

The contract in tools/test-i386-global-alias.py covers an aggregate array with
inline strings, an I64 scalar, and an initially incomplete byte array. It checks
original alias flags and shared addresses, initialized fields, reads from new
input controls after declaration-input release, and mutations followed by another
read. The actual original reference passes in build/i386-global-alias-original-v2.
The pre-change image executes the initial export but rejects publication, retained
in build/i386-global-alias-baseline-v2. The patched native image passes all three cases in
build/i386-global-alias-native-v1. Independent terminal audits verify exact
fixtures and current inputs; the native audit also checks fixture-only volume
changes and unchanged boot bytes.

An initial byte-exact prototype assumed zero padding after string terminators.
The original leaves those bytes unspecified. The formal oracle checks every
initialized field and string byte through its terminator, plus all scalar and
byte-array data; it excludes only the eight unspecified trailing string-array
bytes. Raw observations remain available in the exported files. This does not
weaken publication or lifetime requirements.

Both bootstrap generations and the full native build pass stable source pins.
Both the 8 MiB normal and 16 MiB diagnostic images pass all 307200 welcome
pixels and normal startup. Both diagnostic program/ownership/file-cleanup phases
pass; see build/i386-global-alias-memory-audit.json. The source-loaded parser/optimizer
retry now publishes all 17 stages, passes 24 token cases and passes graph mask 63
for integer/F64 parsing and folding (build/i386-public-expression-loader-v9).
This diagnostic does not deliver the executable public expression API. Standalone
unresolved globals across separate inputs, malformed aliases, all type combinations
and C1–C5 qualification remain open; this change handles completion within one
input rather than publishing an unresolved header as a completed definition.
