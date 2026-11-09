# Budget schedule validation through real forms

`tools/test-i386-budget-validation.py` drives Budget's real `t` action from an
empty report. It accepts a zero-period interval, a negative-period interval and
the Null recurrence type with a positive period. Each must return directly to
the unchanged report with empty entry/template lists and no data or string file.
The Null selection uses the actual nested LS menu, whose complete signed action
values, default and cursor are checked against the original.

A fourth attempt accepts a valid interval, fills a transaction with GHOST/VOID
accounts and `discard me`, then cancels that transaction form. The schedule must
return with all previously committed values. Replacing its period with zero
must leave the backing period unchanged until acceptance, then reject the
schedule. The cancelled entry must neither create account names nor transactions.

All seven form phases export separate raw documents, visible tags and complete
portable backing records. Four report captures must remain empty. The final
Shift-Escape abort must restore caller documents, menu, settings, geometry and
autocomplete state; mask 1023 combines these checks. Native execution also
requires fresh arithmetic 42 and equality of every file's bytes, attributes and
timestamp against the snapshot after installation. Only the probe addition and
installed accounts file may differ from the input image.

The original accepted period 1.00 has exact bits `3FF0000000000001`, while native
uses `3FF0000000000000` under its established binary64 policy. Both are checked
exactly in the retained and invalidated backing records; there is no tolerance.
No application handlers create or edit test entries, and no Budget source port
beyond the established sort-slot and pointer-width adaptations is permitted.

```
python3 tools/test-i386-budget-validation.py --archive ARCHIVE --out FRESH_ORIGINAL
python3 tools/test-i386-budget-validation.py IMAGE --reference FRESH_ORIGINAL --out FRESH_NATIVE
```

This covers rejection and cancellation, not date boundary expansion, mouse,
resource profiling or complete Budget/C1–C5 qualification. Passing evidence is
recorded only after the original and native controls finish and raw captures
are independently revalidated.

Canonical controls are `build/budget-validation-original-v2/result.json` and
`build/budget-validation-native-v2/result.json`, both passing mask 1023 with
unchanged inputs. `build/budget-validation-audit-v1/result.json` revalidates all
raw captures and source pins and rejects 323 corruptions. Original/native
captures are identical except byte 36 of retained/invalidated backing records.
The native run preserves 1877 existing files and the complete post-install tree.

The first native observation timed out waiting for the Null draft. Stopped RAM,
registers and the final screen retain shifted field input. The original observer
announced draft readiness while the nested picker was still returning. Its only
fixture correction waits for child closure and exact Null tag/backing zero
before field readiness; final original/native controls pass. The failed receipt,
exact synchronization patch and verified capture hashes remain in the audit
folder. No runtime or application source changed.

Form screenshots are immediate observations after observer markers; the exact
assertions use document structure, tags and backing bytes. A settled form-raster
or color comparison is not part of this component's passing claim.
