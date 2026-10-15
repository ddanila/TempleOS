# Key names and descriptions for complete editor input

These are dependencies of the full original DocPutKey dispatcher, not a
replacement for it. The candidate shares complete Char2KeyName and KeyDescSet
bodies through Kernel/KeyNameCore.HC and Kernel/KeyDescriptionCore.HC. Original
Keyboard.HC and KeyDev.HC include those same bodies.

## Test-first evidence and one original bug fix

The paired guest fixture is
`tests/guest/i386-key-description-reference/KeyDescription.HC`. The initial
current-original bounded tests passed masks [63,63]. An extended control-name
case then reproduced an original bug on the pinned reference: observed masks
[47,63] in `build/i386-c4-key-description-control-red`, with unchanged inputs.
With include_ctrl FALSE, the default control-character branch appended to an
uninitialized stack buffer. Initialize its first byte before dispatch; the
remaining name body is unchanged, and the description body is byte-identical.
This is an explicit shared bug fix rather than reproducing undefined text.

Both original bootstrap generations pass after extraction/fix. The refreshed
current-source original oracle passes [63,63] with unchanged inputs in
`build/i386-c4-key-description-wide-reference`. The earlier native Console
106 prerequisite fails at undefined KeyDescSet in
`build/i386-c2-key-description-red`; its fixture body is not reached.

The name oracle checks independent literal expectations for Enter, Backspace,
Tab, space/shift-space, Escape/shift-Escape, ordinary printable bytes (including
byte 36), empty/special/nonprintable results, and control letters with/without
the prefix. All allocated names are freed and exact caller heap is checked.
The description oracle checks wide signed numeric/string formatting, stable handler
identity at one call site, distinct identity at another, empty description,
exact caller heap, and restoration of prior global text/handler.

The first fixture used a bare dollar source literal, which DolDoc interpreted
before compilation. Its captured original screen showed a parse failure. The
replacement constructs byte 36 explicitly; local bytes use assignments rather
than unsupported local aggregate initialization. These failed fixture attempts
are not passing behavior evidence.

## Native interface and limits

Console 107 adds Char2KeyName, KeyDescSet and the existing keydev global to the
public key-device header and export table (262 console exports total). The
shared description body uses the existing full formatter and public Caller
provider; it preserves keydev.desc and keydev.hndlr semantics. The native key
hook dispatcher/global are reused, and the canonical printable bitmap supplies
name classification. Public task/document layouts and console services remain
unchanged; Memory remains 26.

Reproduce with fresh output directories:

```
python3 tools/test-i386-key-description-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-key-description.py build/i386-c2-key-description-global-cross/kernel.img --out build/NEW-native
```

This does not qualify arbitrary/out-of-range character values, oversized
descriptions, ScanCode2KeyName, every caller depth, concurrent description
writers or exceptional allocation. Full original DocPutKey, actual chooser,
GetStr/TimeClock and application workflows remain separate gates. Native
qualification results are recorded in the latest PLAN.md checkpoint.

The first cross-build rejected taking the AOT address of an extern data
declaration. The final candidate defines the existing native keydev object in
the console publication unit before export setup and removes its later
declaration from KeyDevRuntime.HC. It does not allocate a second object or
change its type. This compiler constraint is distinct from runtime behavior.


## Final native qualification

`build/i386-c2-key-description-global-cross` passes with the limited 386 audit
(96 BIOS / 255 protected instructions), and all 1,491 source/build pins match.
Both bootstrap generations pass. Native `build/i386-c2-key-description-contract`
passes five commands, exact fixture readback, both expected masks of 63 and
unchanged inputs. Hook dispatch passes 21 commands with exact persisted values;
clock/undo passes ten. Normal 8 MiB startup passes nine checks in 52.43 seconds
with zero build-provider loads. Regression result prefixes are
`build/i386-c2-key-description-` (hooks, undo, startup). Full input dispatcher
and C1–C5 qualification remain open.
