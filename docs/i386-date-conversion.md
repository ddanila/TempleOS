# Retained calendar conversion

The original `CDate` and `CDateStruct` declarations now live in
`Kernel/DateTypes.HH`, shared by the original kernel and native public headers.
Their sizes remain 8 and 12 bytes. `Kernel/DateCore.HC` contains the original
calendar conversion, day-of-week, month/year boundary and BCD routines.
ConsoleRuntime 20 retains these nine functions and publishes the writable
`local_time_offset` global. The offset starts at zero; this change does not
connect the native runtime to the RTC or publish `Now`.

This supplies the calendar dependency of the original formatter. General
formatting, document recalculation and a usable editor remain integration work.

## Arithmetic and boundary behavior

Original x64 HolyC lowers division by a positive power of two to a shift,
including signed division. `YearStartDate` now explicitly uses `y1>>2` so its
negative-year behavior survives compilation by the i386 backend, whose division
semantics otherwise differ here. The other year-cycle divisions still truncate
toward zero. This preserves the original calendar rather than substituting a
host Gregorian calendar implementation.

The shared code also fixes two original boundary defects: month-table scans
check the index before reading the next entry, and December's next month is
January (1), not month 0. The latter previously read before the month table.

Time conversion preserves the original upward quantization to 1/10000-second
units: fraction zero decodes with a final unit of one; the largest fraction can
decode as 24:00 without advancing the day. Conversion back wraps the fraction.
Month/year helpers preserve the signed 32-bit date field's wrapping behavior,
whereas `YearStartDate` returns a full signed 64-bit count.

## Verification design

`tools/gen-i386-date.py` independently generates 146 calendar vectors using a
year search, month lengths and integer fractional scaling. They include signed
32-bit date extremes, negative dates, century/400/4000-year boundaries and
fraction extremes. Separate cases cover eleven year starts and seven BCD inputs.
`DateCheck` also verifies record layout and writable offset use, for 1333 checks.

The cross-build compares the vectors with both the shared implementation and a
copy of the pre-port original routines. The original December last-day branch
is excluded because of its invalid array access; the shared replacement is
checked against independently calculated expectations. The native input suite
compiles and executes the same check through retained public bindings.

Both original x64 rebuild/reboot generations and the full native suite pass.
The native suite completes 203 commands / 266 lines, 1333 calendar checks and
4107 numerical checks, exact VGA comparisons, recovery checks and all 17 module
rejections. All 1160 OS source hashes, 18 build-input hashes and both disk hashes
match the validated worktree.

ConsoleRuntime 20 retains 200744 bytes (200728 image bytes), an increase of
13072 bytes. Kernel size remains 365760 bytes with 23360 bytes of bootstrap
headroom. Normal boot measured 25.386 seconds; diagnostics measured 138.591.
These are QEMU 486 / 8 MiB results, not strict 386 or physical-machine acceptance.
