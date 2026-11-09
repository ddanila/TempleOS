# Budget editing and copying through keyboard input

This C1/C3 workflow extends the accepted-new-entry and cancellation session with
editing and copying an existing transaction. It uses the complete Budget source,
its real popup forms and QEMU keyboard events. The observer reads documents,
transaction lists and caller state; it does not fill fields, call the application
key handler or inject task messages.

The native source checker retains the reviewed `BgtStrs.HC` pointer-width port.
The eleven inventoried Budget files retain their pinned repaired references,
with only that reviewed source port. The additional compressed account template
is checked against the archive used by the original control. The native base
image has no installed Budget data; installation and initial UI entry are part
of the session.

## Workflow and exact oracles

1. Cancel a fully filled unwanted transaction and require an empty document/list
   and no data/string-table files.
2. Enter the original 09/04/1998, 125.50 BANK-to-RENT transaction with description
   `popup entry`. Check the exact account report and a nonzero transaction ID.
3. Select that actual entry with Home, open its edit form with Enter, tab to its
   description and append `!` with Ctrl-Right followed by typing. Accept with
   Escape and check the changed report and transaction fields.
4. Select the entry and press `c`. Accept the populated copy form. Require two
   distinct entries with equal values and independently allocated credit, debit
   and description strings. Check both exact report rows and their cursor marker.
5. Exit with Escape to save. Independently decode both 32-byte data records,
   count and EOF, the twelve-entry string table and unchanged installed accounts.
6. Reopen and abort with Shift-Escape. Both entries and all persisted files must
   match the saved records. Native qualification requires an actual QEMU shutdown
   and restart, plus unchanged file bytes, attributes and timestamps after abort.

The masks also check observer completion, restored caller documents, menus,
settings, window bounds, autocomplete activity and same-session file readback.
The native console must render a fresh 42 after both application exits. These
are not complete heap, application, desktop, performance or C5 release checks.

## Original behavior that the oracle preserves

The populated edit form formats its date with the original two-digit `%D`.
Accepting `09/04/98` reparses it as day 766525 (2098), compared with day 730000
for the explicitly typed 1998 input. It also reparses the displayed amount;
the saved binary64 bits become `0x405F600000000002`, two ULPs above exactly
125.5, while the displayed amount remains 125.50. The original copied records
must retain those exact bits. Native uses the already established exact-power/binary64
policy from [numeric compatibility](i386-lex-number.md) and
[software floating point](i386-f64-backend.md): its amount remains exactly 125.5
(`0x405F600000000000`). An independent rational-power/host binary64 oracle
derives the native result. Both target outputs are checked exactly; only bytes
32 and 64 of the 80-byte saved data may differ between targets. The native data
must fail the original-bit oracle and vice versa. No tolerance is introduced.
The workflow records these round trips explicitly.

The first report row shows balance -125.50 and amount 125.50; the second shows
balance -251.00 and amount 125.50. The live copy session's cursor marker lies
between the rows, while a fresh reopened report places it at the end. Only
transaction pointer addresses are normalized. Marker position, field values and
floating-point bits are checked explicitly.

Original references `build/budget-edit-copy-original-v5/result.json` and
`build/budget-edit-copy-original-v6/result.json` pass mask 511 and same-boot
reopen mask 63 with unchanged inputs and identical normalized outputs. Earlier
exploratory failures are retained. In particular, native v1 records the mismatch
when the original-only amount oracle was applied to the native numerical policy.
The final shared fixture selects exact expected amount bits by target pointer
width; it does not change application calculations or serialization. The
observer waits for a new document with Budget's handler published after each
accepted edit/copy, so popup teardown alone cannot race with application commit
on the original two-CPU system.

Reproduce with fresh output directories:

```
python3 tools/test-i386-budget-edit-copy.py --archive build/i386-operand-cross-v1/exports/BudgetAccts.DD.Z --out OUT_REFERENCE
python3 tools/test-i386-budget-edit-copy.py build/i386-operand-cross-v1/kernel.img --reference OUT_REFERENCE --out OUT_NATIVE
```

Editing/copy cancellation, alternate account choices, templates, mouse workflows,
full Budget qualification and complete C1–C5 acceptance remain open.

## Budget workflow coverage map

The original `BgtPutKey` switch and menu define the following interaction paths.
This map keeps the remaining application scope visible; passing the edit/copy
workflow does not remove any of these paths from C3.

| Original path | Existing executable evidence | Remaining workflow |
| --- | --- | --- |
| `n`: new entry | `test-i386-budget-entry.py`; this runner | Alternate dates, amounts and account choices |
| Enter: edit entry | This runner changes an existing description | Cancel edit; change date, amount and both accounts; save/reopen |
| `c`: copy entry | This runner accepts populated copy, checks independent strings and both saved records | Cancel copy; change the copied fields and verify the source remains intact |
| Ctrl-Y: delete | `test-i386-budget-session.py` selects/deletes/saves, then deletes/aborts after native reboot | Mouse selection and deletion |
| Escape / Shift-Escape | Entry/session runners cover save, abort and caller restoration; this runner checks edited/copied persistence | Equivalent menu and mouse routes |
| `v`: view account | `test-i386-budget-views.py` checks reports through component calls | Drive actual account picker; accept and cancel; verify balances and return |
| `a`: accounts file | Installation/storage runners check the initial account file | Open its real editor, rename/recolor an account, save/reopen and cancel |
| `t`: new template | No UI qualification | Create a schedule, expand it, save/reopen, edit and delete it |
| `p`: periodic entry | No UI qualification | Apply a temporary schedule to an entry and check generated transactions/persistence |
| Enter / Ctrl-Y on template-derived rows | No UI qualification | Edit/delete the owning template and check regeneration and saved template data |

Reference capture, exact persisted-record oracles and native public interaction
are required for each remaining workflow. Existing component tests do not stand
in for untested UI paths. Normal startup/memory profiles, repeated-use resource
recovery and full native release generations also remain separate acceptance work.

## Final verification

`build/budget-edit-copy-native-v3/result.json` passes masks 511 and 63 on
`build/i386-operand-cross-v1/kernel.img` at 64 MiB with the FPU disabled.
Cold reopening skips installation and data seeding. Both transactions survive,
read-only abort preserves every file's bytes, attributes and timestamps, and both
console returns render fresh arithmetic 42. The only session additions/changes
are the probe and three installed Budget files; 1,877 existing files remain
unchanged. Application and runtime code are unchanged.

The current-runner original control is
`build/budget-edit-copy-original-v7/result.json`. Its normalized outputs match
the two earlier identical-fixture controls v5/v6. Native's reference points to
that preserved v5 control; the final audit also compares it with v7. Historical
runner hashes are checked against their saved runner copies. Native v2's failed
host comparison is retained; the final runner applies the same strict two-byte
architecture check to both initial save and reopened data.

`build/budget-edit-copy-audit-v1/result.json` checks the receipts, original
boot overlay fixture, delivered native fixture, raw exports, source/asset
provenance, 1,850 runtime source hashes and seven oracle corruption/wrong-target
rejections. It preserves `inventory-at-test.json` and verifies that later
inventory edits only append test receipts: original reference data and all
qualification states stay unchanged. Eleven inventoried Budget files plus the
additional compressed template are checked independently. Inventory guards pass;
qualification remains 2/686 and C1–C5 stay open.
