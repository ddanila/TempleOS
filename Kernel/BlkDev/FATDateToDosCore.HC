U0 CDate2Dos(U16 *t,U16 *d,CDate cdt)
{
  CDateStruct ds;
  Date2Struct(&ds,cdt);
  *d=ds.day_of_mon+(ds.mon+(ds.year-1980)<<4)<<5;
  *t=ds.sec>>1+(ds.min+ds.hour<<6)<<5;
}

