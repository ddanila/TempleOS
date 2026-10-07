I64 dp_value;
I64 DPValue(){return dp_value;}
I64 DollarParserContract()
{
  CDoc *d=DocNew("C:/DollarParser.DD",Fs);
  CDocEntry *e;
  I64 mask=0;
  dp_value=7;
  e=PrsDollarCmd(d,"BT,\"PLAY\",LE=2+3*4");
  if(e->type_u8==DOCT_BTTN&&e->left_exp==14&&StrCmp(e->tag,"PLAY")==0)mask|=1;
  QueInit(e);DocEntryDel(d,e);
  e=PrsDollarCmd(d,"DA-P,LEN=STR_LEN-1,A=\"Name:%s\"");
  if(e->type_u8==DOCT_DATA&&e->len==STR_LEN-1&&StrCmp(e->aux_str,"Name:%s")==0)mask|=2;
  QueInit(e);DocEntryDel(d,e);
  e=PrsDollarCmd(d,"FG,3.75");
  if(e->type_u8==DOCT_FOREGROUND&&e->attr==3)mask|=4;
  QueInit(e);DocEntryDel(d,e);
  e=PrsDollarCmd(d,"BT,\"P\" \"LAY\",LE=dp_value");
  if(e->type_u8==DOCT_BTTN&&e->left_exp==7&&StrCmp(e->tag,"PLAY")==0)mask|=8;
  QueInit(e);DocEntryDel(d,e);
  e=PrsDollarCmd(d,"BT,\"RAW\",LE=1.5");
  if(e->type_u8==DOCT_BTTN&&e->left_exp==0x3FF8000000000000)mask|=16;
  QueInit(e);DocEntryDel(d,e);
  e=PrsDollarCmd(d,"BT,\"SUM\",LE=DPValue()+1");
  if(e->type_u8==DOCT_BTTN&&e->left_exp==8)mask|=32;
  QueInit(e);DocEntryDel(d,e);
  DocDel(d);
  return mask;
}
