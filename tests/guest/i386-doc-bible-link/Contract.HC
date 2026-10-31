U0 BLMark(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 DocBibleLinkContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  I64 mask=0;
  BLMark("BL first begin\n");
  if(Ed("BF:Genesis,1:1",EDF_BAIL))mask|=1;
  BLMark("BL first end\n");
  if(Ed("bf:Genesis,1:1-3",EDF_BAIL))mask|=2;
  BLMark("BL second end\n");
  if(!Ed("BF:NoSuchBook,1:1",EDF_BAIL))mask|=4;
  BLMark("BL missing end\n");
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  return mask;
}
