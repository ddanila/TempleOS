#ifndef I386_PUBLIC_DATE_INCLUDED
#define I386_PUBLIC_DATE_INCLUDED
#include "/Kernel/DateTypes.HH"
public _extern _YEAR_START_DATE I64 YearStartDate(I64 year);
public _extern _STRUCT_TO_DATE CDate Struct2Date(CDateStruct *ds);
public _extern _DAY_OF_WEEK I64 DayOfWeek(I64 day);
public _extern _DATE_TO_STRUCT U0 Date2Struct(CDateStruct *ds,CDate date);
public _extern _FIRST_DAY_MONTH I64 FirstDayOfMon(I64 day);
public _extern _LAST_DAY_MONTH I64 LastDayOfMon(I64 day);
public _extern _FIRST_DAY_YEAR I64 FirstDayOfYear(I64 day);
public _extern _LAST_DAY_YEAR I64 LastDayOfYear(I64 day);
public _extern _BCD_TO_BIN I64 Bcd2Bin(U64 value);
public extern CDate local_time_offset;
#endif
