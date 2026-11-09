# Budget account picker through keyboard input

This C1/C3 workflow exercises the complete Budget application's `v` command,
its real popup menu and account-view regeneration. The fixture explicitly seeds
three transactions before opening the UI; it does not claim transaction-entry
coverage. During interaction, the observer only reads documents, literal-link
values, transaction state and caller settings. Input comes through QEMU keyboard
events rather than application callbacks or injected task messages.

## Workflow

1. Seed and export three fixed-date records: WAGES-to-BANK salary 100,
   BANK-to-FOOD groceries 20 and BANK-to-RENT rent 30. Seed the account list and
   string table through the original storage functions.
2. Start Budget on BANK. Check all three report rows and balances 100, 80, 50.
   Home/Down selects the middle transaction.
3. Press `v`. Require the BANK default in the thirteen-account menu. Home/Down
   selects RENT; the observer must see that selection before Space accepts it.
   The menu uses literal left actions, so acceptance uses Space.
4. Check the regenerated RENT report: balances 0, 0, 30, all transaction IDs
   retained, and the middle row still selected.
5. Press `v` again. Require the RENT default, select BANK with Home/Down, then
   cancel with Shift-Escape. The RENT document, selection, transaction identities
   and all logical record fields must remain unchanged. After Budget returns,
   its final account must still be RENT.
6. Abort Budget with Shift-Escape. Require restored caller documents, menu,
   settings, window bounds and autocomplete state, plus exact file readback.
7. Native execution shuts down QEMU and restarts the same disk. Reopen without
   installation or seeding. Budget must reset to BANK and display all three
   original records. Abort and require unchanged file bytes, attributes and
   timestamps. Both console returns must render fresh arithmetic 42.

The original reference reopens in the same boot. It is not original cold-boot
proof. The picker path is the view-account chooser; nested credit/debit pickers
inside entry forms and mouse selection remain separate work.

## Exact oracles

The menu order captured from the pinned original system is:

```
JOB CASH FOOD MISC CHARITY RENT WAGES HEALTH CREDIT CLOTHS CAR UTILITIES BANK
```

BANK is index 12 and RENT index 5. Both menu documents must match the original
header, every account name, foreground color, literal-link action and cursor
marker. Each literal action must point to its displayed account string. All
thirteen nonzero, unique literal values must remain stable between openings.
Across original and native, only decimal `LE` addresses and transaction `U`
addresses are normalized. Within a session, identity checks retain the actual
addresses.

The independent host checker decodes the complete 112-byte transaction file,
including count three, each date/type/flags/account/description/amount field and
EOF zero. It checks all sixteen string-table entries and the thirteen-account
file. Post-interaction files must also equal the raw seed exports byte for byte.
The amounts 100, 20 and 30 are exactly representable on both targets; these
records require exact cross-target equality without a numerical exception.

Mask 2047 covers normal caller restoration/readback, both defaults, accepted
RENT regeneration and row preservation, changed BANK selection before cancel,
unchanged cancelled state and both menus' literal-link values. The reopened
session requires mask 63 and BANK both while running and after return. Live
transaction checks include dates, types, flags, amounts, names, descriptions,
empty templates and doubly linked list structure.

## Reproduction

Use fresh output directories:

```
python3 tools/test-i386-budget-account-picker.py --archive build/i386-budget-pointer-cross-v1/exports/BudgetAccts.DD.Z --out OUT_REFERENCE
python3 tools/test-i386-budget-account-picker.py build/i386-budget-pointer-cross-v1/kernel.img --reference OUT_REFERENCE --out OUT_NATIVE
```

The source checker retains the reviewed `BgtStrs.HC` sort-slot port and verifies
three explicit cancellation casts in `BgtMain.HC`/`BgtEntry.HC`. The other eight
inventoried sources/assets remain byte-identical to their repaired references. The
compressed account template is shared with the original control. The normal
native image runs at 64 MiB with the FPU disabled.

Account-file editing, templates and periodic entries, other entry-field changes,
nested credit/debit pickers, mouse, resource profiles, full Budget qualification
and complete C1–C5 release acceptance remain open.

## Cancellation defect and pointer-width repair

The unchanged native caller fails in
`build/budget-account-picker-native-v2/result.json`: mask 1535 lacks cancellation
bit 512, and the final RENT balance becomes zero. An earlier native run captured
the observer state before the incorrect caller branch completed and passed.
The final fixture also checks the account after Budget returns, beyond popup
teardown and callback completion. Both complete original controls stay correct.

Diagnostic wrappers on the unchanged image record both `DocMenu` and the servant
source returning `-1`. The error occurs when Budget stores that value in `U8 *`
and tests it against an eight-byte integer. The independent twelve-field
`--pointer-boundary` probe checks the existing ABI without dereferencing the
sentinel:

| Observation for cancellation value -1 | Original x64 | Native i386 |
| --- | --- | --- |
| Pointer storage | 8 bytes | 4 bytes |
| Pointer value widened to integer | `0xFFFFFFFFFFFFFFFF` | `0x00000000FFFFFFFF` |
| `p>=0` | false | true |
| `p==-1` | true | false |
| `p==(-1)(U8 *)` | true | true |
| Explicit pointer cast of `0x100001234` | `0x100001234` | `0x1234` |

The i386 ABI already requires comparisons with negative pointer sentinels at
target pointer width. `BgtMain.HC` now checks the picker result against
`DOCM_CANCEL(U8 *)`; the same explicit cast replaces both raw integer comparisons
in `BgtEntry.HC`'s credit/debit branches. All three sites preserve the defined
return set: an account-string pointer or cancellation. Runtime/compiler pointer
normalization, job delivery and the ABI remain unchanged. The source checker
admits exactly these three edits in addition to the earlier sort-slot port.

`build/budget-pointer-boundary-original-v1` and
`build/budget-pointer-boundary-native-v1` pass their exact twelve-field records.
The ordinary pinned original control `build/budget-account-picker-original-v7`
and the current-source original control
`build/budget-account-picker-shared-original-v1` both pass masks 2047/63 and
identical normalized outputs. The latter loads all eleven reviewed current
Budget files on the original runtime, proving the casts preserve its behavior.

The repaired image is `build/i386-budget-pointer-cross-v1/kernel.img`.
`build/budget-account-picker-fixed-native-v1` and `-v2` both pass mask 2047 and
actual cold-reopen mask 63, including the post-return RENT/BANK assertions.
Read-only abort preserves every file's bytes, attributes and timestamps; both
console returns render 42. The session preserves 1,877 existing files and changes
only its probe and three explicitly seeded Budget files. All three data files
match the original exactly. The existing modified-entry/copy cancellation and
cold-reopen regression also passes in `build/budget-pointer-entry-regression-v1`.
This does not qualify the nested credit/debit picker UI workflows.

Both original bootstrap generations pass. The repaired build checks 1,850 source
and 26 helper hashes, sixteen modules and the 96 BIOS/332 protected-mode 386 boot
instruction audit. Only the two Budget source files differ from the prior build;
the kernel and all sixteen runtime module binaries are byte-identical. ABI stays
Compiler104/Console264/Memory41, 691 exports and 22 mask words.

`build/budget-account-picker-audit-v1/result.json` verifies the failing caller,
trace provenance, exact source/image/fixture delivery, current original and
native records, key order, source-port allowlist, both bootstraps, retained
runtime bytes, entry regression and seventeen corruption/default rejection
checks. It preserves test-time inventory metadata and checks that subsequent
inventory changes only append receipts. Qualification remains 2/686; C1–C5
remain open.

Additional boundary and reviewed-source commands:

```
python3 tools/test-i386-budget-account-picker.py --pointer-boundary --out OUT_POINTER_REFERENCE
python3 tools/test-i386-budget-account-picker.py build/i386-budget-pointer-cross-v1/kernel.img --pointer-boundary --reference OUT_POINTER_REFERENCE --out OUT_POINTER_NATIVE
python3 tools/test-i386-budget-account-picker.py --shared-budget --archive build/i386-budget-pointer-cross-v1/exports/BudgetAccts.DD.Z --out OUT_REVIEWED_ORIGINAL
```
