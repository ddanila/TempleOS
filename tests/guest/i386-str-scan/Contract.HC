I64 StringScanContract()
{
  I64 mask=0,n;
  CDate date;CDateStruct ds;
  CDate saved_offset=local_time_offset;
  F64 value;
  U8 text[32],*ptr=text,*end;
  n=0;end=StrScan("Repeat N:42","Repeat N:%d",&n);
  if(n==42&&!*end)mask|=1;
  StrCpy(text,"");end=StrScan("Name:386","Name:%s",&ptr);
  if(StrCmp(text,"386")==0&&!*end)mask|=2;
  n=0;StrScan("FF","%X",&n);if(n==255)mask|=4;
  n=0;StrScan("1010","%b",&n);if(n==10)mask|=8;
  value=0;StrScan("12.5","%f",&value);if(value==12.5)mask|=16;
  n=0;end=StrScan("427","%*d",2,&n);
  if(n==42&&*end=='7')mask|=32;
  n=-1;StrScan("VGA","%z",&n,"386\0VGA\0");if(n==1)mask|=64;
  local_time_offset=0;date=0;
  StrScan(" 12 / 31 / 2024 ","%D",&date);
  MemSet(&ds,0,sizeof(CDateStruct));ds.year=2024;ds.mon=12;ds.day_of_mon=31;
  if(date==Struct2Date(&ds))mask|=128;
  local_time_offset=saved_offset;
  return mask;
}
