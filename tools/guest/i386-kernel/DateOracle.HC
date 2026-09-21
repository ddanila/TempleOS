//Original pre-port date bodies for independent x64 comparison.
U16 Originalmon_start_days1[12]={
0,31,59,90,120,151,181,212,243,273,304,334};
U16 Originalmon_start_days2[12]={
0,31,60,91,121,152,182,213,244,274,305,335};

I64 OriginalYearStartDate(I64 year)
{//32-bit day since AD 0, given year number.
  I64 y1=year-1,yd4000=y1/4000,yd400=y1/400,yd100=y1/100,yd4=y1/4;
  return year*365+yd4-yd100+yd400-yd4000;
}

CDate OriginalStruct2Date(CDateStruct *_ds)
{//Cvt CDateStruct to CDate.
  CDate cdt;
  I64 i1,i2;
  i1=OriginalYearStartDate(_ds->year);
  i2=OriginalYearStartDate(_ds->year+1);
  if (i2-i1==365)
    i1+=Originalmon_start_days1[_ds->mon-1];
  else
    i1+=Originalmon_start_days2[_ds->mon-1];
  cdt.date=i1+_ds->day_of_mon-1;
  cdt.time=(_ds->sec10000+100*(_ds->sec100+100*(_ds->sec
	+60*(_ds->min+60*_ds->hour))))<<21/(15*15*3*625);
  return cdt;
}

I64 OriginalDayOfWeek(I64 i)
{//Day of week, given 32-bit day since AD 0.
  i+=CDATE_BASE_DAY_OF_WEEK;
  if (i>=0)
    return i % 7;
  else
    return 6-(6-i)%7;
}

U0 OriginalDate2Struct(CDateStruct *_ds,CDate cdt)
{//Cvt CDate to CDateStruct.
  I64 i,k,date=cdt.date;
  _ds->day_of_week=OriginalDayOfWeek(date);
  _ds->year=(date+1)*100000/CDATE_YEAR_DAYS_INT;
  i=OriginalYearStartDate(_ds->year);
  while (i>date) {
    _ds->year--;
    i=OriginalYearStartDate(_ds->year);
  }
  date-=i;
  if (OriginalYearStartDate(_ds->year+1)-i==365) {
    k=0;
    while (date>=Originalmon_start_days1[k+1] && k<11)
      k++;
    date-=Originalmon_start_days1[k];
  } else {
    k=0;
    while (date>=Originalmon_start_days2[k+1] && k<11)
      k++;
    date-=Originalmon_start_days2[k];
  }
  _ds->mon=k+1;
  _ds->day_of_mon=date+1;
  k=(625*15*15*3*cdt.time)>>21+1;
  _ds->sec10000=ModU64(&k,100);
  _ds->sec100=ModU64(&k,100);
  _ds->sec=ModU64(&k,60);
  _ds->min=ModU64(&k,60);
  _ds->hour  =k;
}

I64 OriginalFirstDayOfMon(I64 i)
{//First day of month, given 32-bit day since AD 0.
  CDateStruct ds;
  CDate cdt=0;
  cdt.date=i;
  OriginalDate2Struct(&ds,cdt);
  ds.day_of_mon=1;
  cdt=OriginalStruct2Date(&ds);
  return cdt.date;
}

I64 OriginalLastDayOfMon(I64 i)
{//Last day of month, given 32-bit day since AD 0.
  CDateStruct ds;
  CDate cdt=0;
  cdt.date=i;
  OriginalDate2Struct(&ds,cdt);
  ds.mon++;
  if (ds.mon==13) {
    ds.mon=0;
    ds.year++;
  }
  ds.day_of_mon=1;
  cdt=OriginalStruct2Date(&ds);
  return cdt.date-1;
}

I64 OriginalFirstDayOfYear(I64 i)
{//First day of year, given 32-bit day since AD 0.
  CDateStruct ds;
  CDate cdt=0;
  cdt.date=i;
  OriginalDate2Struct(&ds,cdt);
  ds.day_of_mon=1;
  ds.mon=1;
  cdt=OriginalStruct2Date(&ds);
  return cdt.date;
}

I64 OriginalLastDayOfYear(I64 i)
{//Last day of year, given 32-bit day since AD 0.
  CDateStruct ds;
  CDate cdt=0;
  cdt.date=i;
  OriginalDate2Struct(&ds,cdt);
  ds.day_of_mon=1;
  ds.mon=1;
  ds.year++;
  cdt=OriginalStruct2Date(&ds);
  return cdt.date-1;
}

I64 OriginalBcd2Bin(U64 b)
{
  I64 i,res=0;
  for (i=0;i<16;i++) {
    res=res*10+b>>60;
    b<<=4;
  }
  return res;
}

I64 OriginalDateCheck()
{
  I64 i,count=0;
  U64 *row;
  CDate value;
  CDateStruct ds;
  for(i=0;i<DATE_VECTORS_COUNT;i++) {
    row=date_vectors+i*10; value=row[0];
    OriginalDate2Struct(&ds,value);
    if(ds.year!=row[1] || (&ds)(U64 *)[0]!=row[2]) return -1000-i;
    if(OriginalStruct2Date(&ds)!=row[3]) return -2000-i;
    if(OriginalFirstDayOfMon(value.date)!=row[4]) return -3000-i;
    //The old December path accesses before its month array; do not use it as an oracle.
    if(ds.mon!=12 && OriginalLastDayOfMon(value.date)!=row[5]) return -4000-i;
    if(OriginalFirstDayOfYear(value.date)!=row[6] || OriginalLastDayOfYear(value.date)!=row[7]) return -5000-i;
    if(OriginalDayOfWeek(value.date)!=row[8] || OriginalYearStartDate(ds.year)!=row[9]) return -6000-i;
    count++;
  }
  return count;
}
