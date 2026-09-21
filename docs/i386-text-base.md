# Native text-base drawing primitives

ConsoleRuntime 17 publishes TextChar, TextLenStr,
TextLenAttrStr and TextLenAttr with the original signatures. They write a native
80-by-60 U32 text-cell staging buffer exposed as i386_text_base. This buffer is
not yet attached to full document presentation or the original gr global.
The normal command console still uses its existing text/VGA presentation path.

Kernel/TextBaseCore.HC ports the corresponding x64 assembly policies from
Adam/Gr/GrTextBase.HC to pointer-width-independent HolyC. The original x64
assembly remains the independent reference implementation. Character drawing
applies pixel scroll offsets shifted by three, window/border clipping and final
screen clipping. Span drawing also advances source offsets when clipping at the
left edge. TextLenStr copies the requested length, including embedded NUL bytes,
and replaces only the low character byte of the supplied attribute. Attribute
strings preserve all 32 bits. TextLenAttr stops at the first nonzero character
byte, preserving the original return value even if no cell was changed.

The core accepts explicit surface dimensions and storage. Native wrappers bind
the VGA development profile's 80 columns and 60 rows. The retained surface has
guard cells for bounds checks and is initialized once with the console. These
functions implement the text-base write contract; color/blink/graphics composition
and presentation remain separate dependencies of DocRecalc and the editor.

An isolated x64 oracle allocates a test surface, saves gr.text_base, disables
local interrupts, redirects only the text-base pointer during non-yielding calls,
then restores it and the flags before freeing storage. It compares 256 original
assembly calls against the portable core across clipping, scrolling and span
cases. A shared 12-case corpus checks concrete cell values, untouched cells and
guards on original x64 and retained native bindings. It covers window/screen
edges, borders, negative scroll, embedded NULs and occupied-cell fill termination.

Full document construction, recalculation, graphics presentation, editor input
and the persistent edit/execute/reboot workflow remain open. No reduced document
renderer or replacement editor is introduced by this port.

## Validation and cost

Both x64 rebuild/reboot generations and the full native QEMU/486 8 MiB suite
pass. The original-assembly oracle passes all 256 comparisons, and the shared
12-case corpus passes through original and retained native entry points. The
prompt suite passes 186 commands / 249 lines, seven hardware breaks, eleven
document-lock commands, eight document-selection cases and exact VGA. Existing
dictionary, entry lifetime and reporting checks remain green. Startup recovery
and all 17 module rejection checks pass. All 1142 source hashes, ten build-input
hashes and both disk hashes match.

Normal startup measured 21.725 seconds and separate diagnostics 134.178 seconds.
ConsoleRuntime 17 retains 168024 bytes (168008-byte image), including the guarded
19200-byte cell surface. Kernel size remains 364864 bytes with 24256 bytes of
reserved-load headroom. Service/configuration records remain 32/32 bytes. These
are QEMU/486 results; strict 386 and physical-PC acceptance remain outstanding.
