# Budget mouse row/account selection and exits

The mouse control starts with three constructed, persisted 100.00 BANK-to-RENT
transactions on September 4–6, 1998, described as first/second/third. Creation is
test setup, not mouse-entry qualification. The actual Budget function then runs
its normal View, menu, settings and save/abort paths.

The driver sends PS/2 relative motion and button events. It reads a portable
observer record of the guest's pointer position and uses document entry layout
and window scroll offsets for targets. It never assigns the document cursor,
changes the pointer state, injects task messages or calls a mouse/application
handler. Every movement/position observation and button edge is recorded.

The intended workflow is:

1. Single-click the second report row. Its cursor must be column two, its
   original row identity must remain, and Budget must have focus.
2. Enter opens that row's real edit form. Its complete prefilled backing record
   and visible tags must identify the second transaction. Shift-Escape cancels;
   all three identities, values and the selected row survive.
3. `v` opens the actual account menu. Single-click RENT to activate its literal
   account action; the report must regenerate with balances +100/+200/+300 and
   unchanged transactions and identities.
4. Single-click the first report row and check column two. Double-left-click
   takes the original View's Escape/save path.
5. Reopen without reseeding. The view resets to BANK with balances
   -100/-200/-300. Double-right-click takes Shift-Escape/abort. Native reopening
   requires a real shutdown/reboot without installation or reseeding.

Independent host checks cover exact report bodies and cursor records, live row
identity across selection/cancellation/view changes, account menu colors/order
and nonzero distinct actions, all 112 saved bytes, fourteen indexed strings and
the unchanged accounts file. The constructed amount is exactly representable on
both targets; no decimal parsing difference is involved. Caller documents, menu,
settings, geometry and autocomplete must restore after both exits. Native must
render fresh arithmetic after each return and preserve every file byte, attribute
and timestamp across cold mouse abort.

```
python3 tools/test-i386-budget-mouse.py --archive ARCHIVE --out FRESH_ORIGINAL
python3 tools/test-i386-budget-mouse.py IMAGE --reference FRESH_ORIGINAL --out FRESH_NATIVE
```

This component does not assert settled framebuffer equality, entry creation by
mouse, general desktop/window mouse behavior or repeated-use resource recovery.
Passing claims require completed original/native controls and raw-capture audit.

The complete original control passes masks 1023/63 at
`build/budget-mouse-original-v3/result.json`. The unchanged native fixture fails
at its first row selection in `build/budget-mouse-native-v1/result.json`.
The host observes the pointer at (20,20) and sends left down/up. Stopped RAM,
registers, the final screenshot and public-task analysis are retained. The active
Budget document's cursor remains at the end, with no popup or retirement/I/O
unwind in progress. Its window manager has completed 276 updates.

The native managed window worker currently synchronizes mouse state and renders
windows, but does not call the original WinMgr retained-document click dispatch.
That is an open C2 implementation gap. Packet/button consumption and default
click timing must also be checked when integrating the original dispatch; this
baseline does not infer consumption from host injection alone. The published
test still requires the complete native workflow and returns failure here.
There is no passing native mouse or cold-mouse-reopen claim.

`build/budget-mouse-audit-v1/result.json` audits that open failure and the passing
original control, including 188 rejected corruptions. Portable live snapshots
independently tie report actions to actual row addresses/values/string ownership.
After execution, one host-only assertion was added to reject pointers outside the
fixed supported RAM address range. Test-time runner snapshots, its exact patch
and offline revalidation are preserved; guest execution did not change.

Earlier original prototypes are retained: v1 had unsupported ternary syntax;
v2 selected RENT but computed its next target before the regenerated viewport
settled. Final readiness waits for the application handler and two completed
render frames before reading that target. No application or runtime source
changed. Native mouse integration, settled raster fidelity and resources remain
open; this is an original reference and executable failure baseline.
