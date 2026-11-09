# Budget entry-form account pickers

This C1/C3 workflow enters one transaction through Budget's real `n` form and
its nested credit/debit menus. It complements the `v` view picker: selecting an
account here changes a draft field before any transaction exists. The observer
reads live documents and draft data; QEMU keyboard events perform all input.

The form receives date 09/04/1998, amount 125.50 and description `popup entry`,
leaving both accounts blank. Escape submits the form and opens the credit menu.
Select RENT, then Shift-Escape cancels. The returned form must retain all fields
and both blank accounts. Submit again, select BANK and accept with Space. The
returned form must contain BANK credit and blank debit. Submit to open the debit
menu, select CASH and cancel; BANK and blank debit must survive. Submit again,
select RENT and accept. A final Escape accepts the complete BANK-to-RENT entry;
Escape in Budget saves it. No transaction, data file or string file may exist at
any of the four returned-form checkpoints.

For each menu, the observer must see the requested selection before the host
sends acceptance/cancellation. Exact menu headers, colors, end cursor and eleven
unique, stable literal account values are checked. Their original order is:

```
JOB CASH MISC CHARITY RENT HEALTH CREDIT CLOTHS CAR UTILITIES BANK
```

Normal `DocSave` output omits form data fields. Separate raw tag exports therefore
check every visible date, amount, credit, debit and description field. Independent
amount-bit exports and live backing-data checks also cover the actual draft.
The host checks the complete 48-byte saved record, twelve strings and 97-byte
account file. Transaction identities and final account report are checked.

The exact original numerical policy is explicit. The first returned form retains
amount bits `405F600000000000`; subsequent formatted-form round trips and the
saved original record contain `405F600000000002`. Native retains
`405F600000000000` throughout. Both targets are checked exactly, without a
tolerance. Only the low byte of the saved amount at offset 32 differs. Dates
remain 1998 because each returned form still contains the full four-digit year.

Mask 1023 combines caller restoration/readback with four returned-form checks.
After save, native execution shuts down QEMU and restarts the same image without
installation or reseeding. Read-only reopen/Shift-Escape requires mask 63, the
same saved data and report, and unchanged bytes, attributes and timestamps for
every file. Both native console returns render fresh arithmetic 42. The original
control reopens in the same boot; it is not original cold-boot evidence.

Reproduce with fresh output directories:

```
python3 tools/test-i386-budget-entry-picker.py --archive build/i386-budget-pointer-cross-v1/exports/BudgetAccts.DD.Z --out OUT_REFERENCE
python3 tools/test-i386-budget-entry-picker.py build/i386-budget-pointer-cross-v1/kernel.img --reference OUT_REFERENCE --out OUT_NATIVE
```

The source checker permits only the previously reviewed Budget sort-slot and
three pointer-width cancellation comparisons. This workflow changes no
application/compiler/runtime code. It exercises both nested branches repaired
in [the view-picker checkpoint](i386-budget-account-picker.md).

Account-file editing, alternate entry-field edits, templates/periodic entries,
mouse, repeated-use resource profiles and complete Budget/C1–C5 acceptance remain
open. Component receipts do not qualify the whole application.

Verification receipts are `build/budget-entry-picker-original-v3/result.json`
and `build/budget-entry-picker-capture-native-v1/result.json`. The audit checks raw
fixture/runner/image delivery, keyboard selection/action order, all phase exports,
exact saved records and unchanged runtime source. Twenty-six deliberately
corrupted record/phase/literal-action cases must be rejected. The frozen test-time
inventory is preserved; later inventory changes only append component receipts.
See `build/budget-entry-picker-audit-v1/result.json`. Bundled qualification stays
2/686 and C1–C5 remain active.

The pinned original receipt retains its frozen runner. The subsequent runner
change only corrects the native-only cold-reopen comparison for the established
amount bits; the audit proves that original execution and the fixture are
unchanged. The earlier native-v1 receipt remains failed at that host comparison,
with its completed guest workflow and raw exports retained.

Two unchanged-fixture capture runs, `build/budget-entry-picker-capture-native-v1`
and `-v2`, pass the complete command. Their wrapper only captures stopped CPU/RAM
on a failed close; it changes no interaction or successful exit. A diagnostic
fixture with additional return checkpoints also passes both phases.

However, `build/budget-entry-picker-native-v2/result.json` remains failed: all
four returned-form oracles pass and all three saved files match successful runs,
but `BP done` never arrives. Its final screenshot shows the console. No CPU/RAM
capture exists for that run, so the cleanup/observer-join boundary is unresolved.
The successful runs do not establish that the stall is fixed. It remains a C2/C3
acceptance issue alongside the remaining application workflows.

[Return diagnostics](i386-budget-return-diagnostics.md) add sixteen successful
read-only reopen/abort repetitions and a verified stopped CPU/RAM capture path.
These checks do not reproduce or close the earlier first-close timeout.
