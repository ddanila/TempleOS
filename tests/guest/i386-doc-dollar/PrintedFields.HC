I64 DollarParserContract()
{
  I64 mask=0,n=3,base=Fs->data_heap->used_u8s;
  U8 value[STR_LEN];
  CDoc *d=DocNew("C:/Fields.DD",Fs);
  CDocEntry *name=DocPrint(d,"$$DA-P,LEN=STR_LEN-1,A=\"Name:%%s\"$$"),*repeat,*button;
  StrCpy(value,"386");name->data=value;DocDataFmt(d,name);
  if(StrCmp(name->tag,"Name:386_")==0)mask|=1;
  repeat=DocPrint(d,"$$DA,A=\"Repeat N:%%d\"$$");
  repeat->data=&n;DocDataFmt(d,repeat);
  if(StrCmp(repeat->tag,"Repeat N:3_")==0)mask|=2;
  StrCpy(value,"VGA");n=7;DocDataFmt(d,name);DocDataFmt(d,repeat);
  if(StrCmp(name->tag,"Name:VGA_")==0&&StrCmp(repeat->tag,"Repeat N:7_")==0)mask|=4;
  StrCpy(name->tag,"Name:486_");DocDataScan(d,name);
  if(StrCmp(value,"486")==0&&StrCmp(name->tag,"Name:486_")==0)mask|=8;
  StrCpy(repeat->tag,"Repeat N:-42_");DocDataScan(d,repeat);DocDataFmt(d,repeat);
  button=DocPrint(d,"text$$BT,\"PLAY\",LE=2$$tail");
  if(n==-42&&StrCmp(repeat->tag,"Repeat N:-42_")==0&&button&&
     button->type_u8==DOCT_BTTN&&button->left_exp==2&&StrCmp(button->tag,"PLAY")==0)mask|=16;
  DocDel(d);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
