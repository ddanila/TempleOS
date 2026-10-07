I64 DollarParserContract()
{
  I64 mask=0,n=3,base=Fs->data_heap->used_u8s;
  U8 value[STR_LEN];
  CDoc *d=DocNew("C:/Fields.DD",Fs);
  CDocEntry *name=PrsDollarCmd(d,"DA-P,LEN=STR_LEN-1,A=\"Name:%s\""),*repeat;
  StrCpy(value,"386");name->data=value;DocDataFmt(d,name);
  if(StrCmp(name->tag,"Name:386_")==0)mask|=1;
  repeat=PrsDollarCmd(d,"DA,A=\"Repeat N:%d\"");
  repeat->data=&n;DocDataFmt(d,repeat);
  if(StrCmp(repeat->tag,"Repeat N:3_")==0)mask|=2;
  StrCpy(value,"VGA");n=7;DocDataFmt(d,name);DocDataFmt(d,repeat);
  if(StrCmp(name->tag,"Name:VGA_")==0&&StrCmp(repeat->tag,"Repeat N:7_")==0)mask|=4;
  StrCpy(name->tag,"Name:486_");DocDataScan(d,name);
  if(StrCmp(value,"486")==0&&StrCmp(name->tag,"Name:486_")==0)mask|=8;
  StrCpy(repeat->tag,"Repeat N:-42_");DocDataScan(d,repeat);DocDataFmt(d,repeat);
  if(n==-42&&StrCmp(repeat->tag,"Repeat N:-42_")==0)mask|=16;
  QueInit(name);DocEntryDel(d,name);QueInit(repeat);DocEntryDel(d,repeat);DocDel(d);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
