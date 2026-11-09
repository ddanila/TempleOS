# Budget recurrence boundary API controls

This component calls the original Budget expansion and deletion APIs directly
with constructed templates. It complements the real-form recurrence and
validation workflows; it does not qualify keyboard, mouse or persistence.

Nine schedules run in both template and periodic-copy modes:

| Schedule | Expected generated dates before periodic first-row omission |
| --- | --- |
| Monthly, Jan 31–May 31 1999 | Jan 31, Mar 3, Mar 31, May 1, May 31 |
| Bimonthly, Dec 31 1999–Jun 30 2000 | Dec 31, Mar 2, May 1 |
| Semiannual, Aug 31 1999–Aug 31 2000 | Aug 31, Mar 2, Aug 31 |
| Annual, Feb 29 2000–Mar 1 2003 | Feb 29 2000, Mar 1 in 2001/2002/2003 |
| Reversed monthly range | No rows |
| Equal monthly start/end | One row |
| Null recurrence | No rows |
| Half-day interval, Jan 1–3 2000 | Midnight/noon Jan 1/2, midnight Jan 3 |
| Annual 2051–2053 input | Jan 1 in 1951/1952/1953 |

Day-of-month overflow rolls forward rather than clamping to the last day.
The stored day/month remains unchanged between iterations, so February 31
becomes March 2 in a leap year and April 31 becomes May 1. MyStr2Date's existing
rule subtracts 100 from years above 2050. Periodic copying skips exactly the
first occurrence, leaving equal-bound schedules empty. These original behaviors
are preserved explicitly rather than replaced by conventional calendar rules.

The independent host oracle uses Python dates and exact half-day fixed-point
values. Every expanded date has the same four fraction ticks on both targets.
All eighteen cases export complete portable rows: date, type, flags, exact
constructed amount bits, template/string ownership, string contents and queue
link integrity. Template rows share owner/strings and have type BE_TEMPLATE_COPY;
periodic rows have no template, independently allocated strings and BE_NORMAL.
The fixture deletes every generated family or ordinary copy and requires the
entry queue to be empty after each case. This is not an exact heap profile.

```
python3 tools/test-i386-budget-boundaries.py --out FRESH_ORIGINAL
python3 tools/test-i386-budget-boundaries.py IMAGE --reference FRESH_ORIGINAL --out FRESH_NATIVE
```

The native command checks the installed application against the reviewed source
adaptations, requires all 2,872 output bytes to match the independent oracle and
original capture, preserves every file byte/attribute/timestamp, and renders
fresh arithmetic 42. Constructed amount 100 is exact on both targets; the decimal
form parser is not involved. No installation or seeded persistent data is used.

Canonical controls are `build/budget-boundaries-original-v2/result.json` and
`build/budget-boundaries-native-v2/result.json`, with unchanged inputs.
`build/budget-boundaries-audit-v1/result.json` revalidates both complete captures,
all pinned original blobs, current build/bootstrap sources and 361 rejected
corruptions. The first native setup attempt failed before the API because Budget
requires autocomplete/task-settings definitions. Final native setup loads those
same dependencies used by the real-form tests. The failed observation and exact
setup-only runner patch remain preserved. No runtime or application code changed.
