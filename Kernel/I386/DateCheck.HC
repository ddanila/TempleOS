#include "/Kernel/I386/DateVectors.HC"
I64 DateCheck()
{
  I64 i,count=0;
  U64 *row;
  CDate value,saved;
  CDateStruct ds;
  if(sizeof(CDate)!=8 || sizeof(CDateStruct)!=12 || offset(CDate.date)!=4 || offset(CDateStruct.year)!=8) return -1;
  for(i=0;i<DATE_VECTORS_COUNT;i++) {
    row=date_vectors+i*10; value=row[0];
    Date2Struct(&ds,value);
    if(ds.year!=row[1] || (&ds)(U64 *)[0]!=row[2]) return -1000-i;
    if(Struct2Date(&ds)!=row[3]) return -2000-i;
    if(FirstDayOfMon(value.date)!=row[4]) return -3000-i;
    if(LastDayOfMon(value.date)!=row[5]) return -4000-i;
    if(FirstDayOfYear(value.date)!=row[6] || LastDayOfYear(value.date)!=row[7]) return -5000-i;
    if(DayOfWeek(value.date)!=row[8] || YearStartDate(ds.year)!=row[9]) return -6000-i;
    count+=9;
  }
  for(i=0;i<DATE_YEAR_VECTORS_COUNT;i++) {
    row=date_year_vectors+i*2;
    if(YearStartDate(row[0])!=row[1]) return -7000-i;
    count++;
  }
  for(i=0;i<DATE_BCD_VECTORS_COUNT;i++) {
    row=date_bcd_vectors+i*2;
    if(Bcd2Bin(row[0])!=row[1]) return -8000-i;
    count++;
  }
  saved=local_time_offset; local_time_offset=1(I64)<<32;
  value=YearStartDate(2000)<<32;
  Date2Struct(&ds,value+local_time_offset);
  local_time_offset=saved;
  if(ds.year!=2000 || ds.mon!=1 || ds.day_of_mon!=2) return -9000;
  return count+1;
}
