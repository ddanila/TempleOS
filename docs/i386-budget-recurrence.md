# Budget calendar recurrence, editing and deletion

The real `t` action now has original/native keyboard controls for all four
calendar recurrence types. Each starts empty, opens the nested LS picker,
cancels Annual with Shift-Escape, then selects the literal CANCEL action
(LE=-1). Both retain Interval. It then selects the requested type and accepts
the schedule and a 100.00 BANK-to-RENT base entry described as `plan`.

| Type | Three generated dates | Accepted edit type |
| --- | --- | --- |
| Monthly | 1998-11-04, 1998-12-04, 1999-01-04 | Bimonthly |
| Bimonthly | 1998-11-04, 1999-01-04, 1999-03-04 | Semiannual |
| Semiannual | 1998-11-04, 1999-05-04, 1999-11-04 | Annual |
| Annual | 1998-11-04, 1999-11-04, 2000-11-04 | Monthly |

Home/Enter edits the first generated row. Changing the schedule and cancelling
must retain the original three row identities, owner, strings and schedule.
Repeating and accepting both forms replaces the template and strings, changes
recurrence and description to `edited plan`, and regenerates three rows. Row
allocations may reuse freed addresses. BgtRegen follows the first old menu
pointer reused in the new rows, otherwise the end; the host derives and checks
that cursor from the actual identities instead of prescribing allocator behavior.
Every report U action must equal its corresponding live row address.

Home and Ctrl-Y delete the entire generated family; both template and entry lists
and the report must be empty. Recreating the original type and `plan` transaction
then saving produces exactly 92 bytes: zero ordinary entries, one template, a
44-byte schedule and a 32-byte base entry. Generated rows are reconstructed on
reopening. All twelve indexed strings and the unchanged 97-byte accounts file
are checked exactly. Host calendar dates are independently computed with Python
datetime, including the annual range across leap year 2000.

Separate captures check all thirteen form phases' raw documents, visible tags
and backing records, all six nested menu choices, signed CANCEL action and
cursor, four reports, live owner/string/row identities and complete schedules.
Data fields commit on acceptance, while the LS selection updates its backing
field immediately. Export readiness waits for the final focused data field.
The observer neither creates entries nor calls application handlers.

Both targets expand dates with fraction four under the existing calendar
quantization; stored base dates retain fraction zero. Original 100.00 parses as
bits `4059000000000001`, native as `4059000000000000`, following the established
[numeric policy](i386-lex-number.md). Only byte 84 differs in saved files, and
byte 512 in the prefilled edited-entry backing record. Both policies are checked
exactly, without tolerance.

All four original and four fixed native controls pass masks 16777215/63. Native
runs actually shut down and reboot without Install or reseeding. Read-only
reopen/abort preserves every file's bytes, attributes and timestamp; 1877 existing
files are preserved, and both returns render fresh arithmetic 42. The pre-fix
native-v1 controls all retain the same deadlock and stopped-VM evidence described
in [control retirement](i386-control-retirement.md).

```
python3 tools/test-i386-budget-recurrence.py --kind monthly --archive build/i386-control-retire-cross-v1/exports/BudgetAccts.DD.Z --out FRESH_ORIGINAL
python3 tools/test-i386-budget-recurrence.py build/i386-control-retire-cross-v1/kernel.img --kind monthly --reference FRESH_ORIGINAL --out FRESH_NATIVE
```

Repeat with bimonthly, semiannual and annual. Canonical originals are
`build/budget-recurrence-monthly-original-v2` and the other three
`build/budget-recurrence-KIND-original-v1` directories. Fixed natives are
`build/budget-recurrence-KIND-native-v2`.

After execution, the host verifier gained one additional equality assertion
between the edited report's U actions and live row identities. All eight preserved
captures pass that stronger assertion. Test-time runner snapshots, the exact
post-execution patch, source hashes and offline revalidation are retained under
`build/budget-recurrence-audit-v1`; receipts retain their actual test-time hash.
No guest fixture or execution path changed during this strengthening.

Only the reviewed Budget sort-slot and three pointer-width cancellation source
adaptations remain allowed. No Budget application source changed. These component
receipts do not qualify the entire application: boundary/validation cases, mouse,
repeated-use resources and full C1–C5 acceptance remain open. Bundled qualification
remains 2/686.
