# Native owned definition lists

These validated services prepare original DolDoc initialization;
they do not yet create its dictionaries or an editor session.

DefineLstLoad now shares its construction policy through DefineLstLoadCore.
The entry owns its name, source link, NUL-separated list and index array. Index
pointers refer into the owned list, so changing or releasing the caller buffer
does not invalidate indexed entries. This fixes the original routine's borrowed
index pointers. Standard symbol deletion also releases the index array, which
was previously leaked. Alias entries beginning with @ retain the previous
ordinal and do not add index slots.

An exception handler is installed before the first allocation. Until construction
succeeds, the entry is unpublished; allocation failure destroys its acquired
fields and propagates the exception. HashAdd publishes the completed entry.
The caller must supply a valid, double-NUL-terminated list, as for the original
API. Parent hash tables remain borrowed.

MemoryRuntime 9 retains DefineLstLoad and HashDefineLstAdd and publishes them
through PublicHash.HH. Native source links preserve AD:0x followed by uppercase,
unpadded hexadecimal caller addresses. The wrapper captures its caller from its
native frame; this does not publish a substitute for the general formatting API.
CHashSrcSym and CHashDefineStr now use a shared small header with unchanged field
order, allowing native source to inspect real definition records.

A shared original/native/public-prompt corpus changes the caller's stack buffer,
checks owned index offsets, source metadata, symbol publication, alias ordinals
and list expansion, then unlinks and deletes its definition. Native root and
worker probes inject failure at each of the five allocation points. Existing
public-memory probes require complete backing-heap reclamation afterward.

Next integration: publish ST_COLORS from the original color names, initialize the
original DolDoc command/flag/link definitions and dictionary, then connect the
original document lifecycle. Dictionary entries use private DHT bits overlapping
standard symbol types, so they require a matching generic-entry destructor.

## Validation

Both x64 rebuild/reboot generations pass. The full QEMU/486, 8 MiB native suite
passes original/native list tests, five injected allocation failures in each of
two task phases, 170 prompt commands / 233 lines, seven hardware break cases,
eleven document-lock commands, eight document-selection cases and exact VGA.
Startup recovery and all 17 incompatible-module rejection checks pass.

All 1120 OS hashes, nine build-input hashes and both disk hashes match. Kernel
size is 363584 bytes, leaving 25536 bytes after the 4096-byte early stage within
the 393216-byte reservation. MemoryRuntime 9 retains 158560 bytes. Normal startup
measured 16.708 seconds; separate diagnostics measured 130.147 seconds. These
results do not establish strict 386 compatibility or a usable DolDoc editor.
