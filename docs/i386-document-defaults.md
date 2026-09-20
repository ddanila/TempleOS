# Shared document default tables

Both x64 rebuild generations, the native exception/task fixture and the full
native kernel suite pass. This makes the original document policy tables
initializable without a compiler control or parser dictionary. It does not replace
the original document parser or establish a complete native DocInit.

DocDefaultsInit fills the fixed entry/type defaults and derives the form,
non-tag visibility, data, duplicate-check and clean-scan-code masks. DocInit still
creates the original command/flag/link definition lists and dictionary, then
calls this helper. The helper leaves the dictionary pointer untouched and adds
its clean scan codes without removing caller-added bits, preserving repeated
DocInit behavior. A fresh caller must supply an initially zeroed record.

The default flag assignments use the existing symbolic DOCT/DOCEF constants.
The original hard-coded default string and parser loop are retained independently
in tools/guest/i386-kernel/DocDefaultsOracle.HC. The build compares every byte of
the pointer-free table span against that parser-derived result, including a
caller-added clean-code bit and dictionary ownership preservation.

CDolDocGlbls and the dictionary kind constants now live in Kernel/DocGlobals.HH;
the existing scan-code constants are shared through Kernel/ScanCodes.HH. Field
order, types and values are unchanged. MakeDoc still owns its original doldoc
global and initializes it before loading document services.

The native exception/task fixture executes the same initializer and returns a
64-bit fingerprint of its pointer-free table bytes. The runner compares this with
the x64 fingerprint, so pointer-size differences are excluded while wide entry
flags and all masks are covered. It also tests preservation of a dictionary
pointer and an extra clean-code bit across repeated initialization.

Native production dictionary construction, entry lifecycle, rendering/editing
and persistent save/reboot/reopen acceptance remain open. Native component
initialization is not a claim that the editor is ready.

The native fingerprint is `c98dfea78567acec`, matching x64. The full suite also
passes the independent parser comparison, 166 console commands / 229 input lines,
exact VGA, seven hardware break cases, document locking/selection, startup
recovery and all 17 module rejections. All 1110 OS source hashes, nine build-input
hashes (including the oracle), and both disk hashes match. The preview is refreshed.
Normal QEMU/486 boot at 8 MiB measured 15.003 seconds; diagnostics measured
127.151 seconds. Kernel size and bootstrap headroom remain 363296 / 25824 bytes.
