# Mouse flags in full keyboard scans

Original `KbdBuildSC` places modifier/mouse flags in both the low merged-scan
half and the high raw-scan half. The native public-state and queued-message
adapters previously added mouse flags to only the low half. For example, a
left-held `a` down arrived as `0x0000001E0001001E` instead of the original
`0x0001001E0001001E`.

`NativeKeyboardMouseScan` now replaces only the left/right mouse bits in both
halves. Public `kbd.scan_code`/`last_down_scan_code` and actual queued key messages
use the same adapter. Other bits and the existing no-installed-mouse path are
preserved. Console ABI268 versions the packed-scan behavior.

`tools/test-i386-keyboard-mouse-scan.py` drives actual key down/up events with
host acknowledgements between them, so public keyboard state is captured before
the next key transition. Its eight phases cover all four synthetic MsSet button
combinations and all four physical QMP button combinations. It independently
requires the complete delivered scan, public `kbd.scan_code`, message code,
character and logical buttons: 80 values, plus exact IF/caller/heap and mouse
restoration (mask7). Physical buttons are released and acknowledged before
restoring the original synthetic state. This is not a pending-IRQ or loss probe.

The original passes at `build/keyboard-mouse-scan-original-v1`. The previous full
image fails at `build/keyboard-mouse-scan-native-before-v1`, with mask7 and all
low-half values intact: twelve of sixteen rows lack only the upper mouse bits
in both delivered/public scans. The candidate passes the unchanged exact oracle
at `build/keyboard-mouse-scan-native-v1`, executes fresh42, and preserves all
volume files. The audit rejects all81 single-value corruptions and checks the
precise retained failure rather than merely requiring a nonzero test exit.

The full image is `build/i386-keyboard-mouse-scan-cross-v1/kernel.img`, pinning
1860 source files and26 build helpers. The source-matching classic compiler and
kernel rebuild twice in `build/rebuild-test`; these are not C5 native generations.
The 386 instruction audit passes. Only Kernel and ConsoleRuntime module hashes
change from `i386-vga-wide-cross-v1`; the bare kernel stays457416 bytes.
The 544-value MsSet comparison and32 existing delivered low-half button values
also pass in `build/keyboard-mouse-scan-msset-v1`.

The literal regression is separately committed: actual included source loses a
quoted link but correctly projects ordinary styled text. See
[document literal evidence](i386-document-literal.md). Complete MsgLoop output,
all keys/modifiers, keyboard/mouse ordering and loss/focus/callback permutations,
legacy transitions, original desktop/apps/raster/resources, the existing
console/editor failures and full C1–C5 acceptance remain open. Qualification
stays2/686. This change does not establish complete keyboard or mouse parity.
