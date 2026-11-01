CDate Dos2CDate(U16 t,U16 d)
{
  CDateStruct ds;
  MemSet(&ds,0,sizeof(CDateStruct));
  ds.day_of_mon=d&0x1F; d=d>>5;
  ds.mon=d&0xF;
  ds.year=d>>4+1980;
  ds.sec=(t&0x1F)*2; t=t>>5;
  ds.min=t&0x3F;
  ds.hour=t>>6;
  return Struct2Date(&ds);
}

