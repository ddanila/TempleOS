#ifndef KERNEL_DATE_TYPES_INCLUDED
#define KERNEL_DATE_TYPES_INCLUDED
#help_index "Date/CDate"
#define CDATE_YEAR_DAYS		365.24225
#define CDATE_YEAR_DAYS_INT	36524225
#define CDATE_BASE_DAY_OF_WEEK	0
public I64 class CDate
{
  U32	time;
  I32	date;
};

#help_index "Date;Date/CDate"
public class CDateStruct
{
  U8	sec10000,sec100,sec,min,hour,
	day_of_week,day_of_mon,mon;
  I32	year;
};

#endif
