U8 dta_golden[26]={0xB4,0xB0,0xF1,0xF4,0xF0,0xF1,0xF4,0xF0,0xF1,0xF4,0xF0,0xF1,0xA4,0xA0,0xA1,0xA4,0xC0,0xC1,0xC4,0x90,0x91,0x94,0x90,0x91,0x94,0x90};
I64 JRContract(I64 unused)
{
  I64 mask=0,i;
  Bool upper=TRUE,lower=TRUE;
  for(i=0;i<26;i++) {
    if(DrvTextAttrGet('A'+i)!=dta_golden[i])upper=FALSE;
    if(DrvTextAttrGet('a'+i)!=dta_golden[i])lower=FALSE;
  }
  if(upper)mask|=1;
  if(lower)mask|=2;
  U8 *current=FileNameAbs("/"),*boot=FileNameAbs("::/"),*home=FileNameAbs("~/");
  if(current && Drv2Let==*current && DrvTextAttrGet(0)==DrvTextAttrGet(*current))mask|=4;
  if(boot && home && DrvTextAttrGet(':')==DrvTextAttrGet(*boot) && DrvTextAttrGet('~')==DrvTextAttrGet(*home))mask|=8;
  Free(current);Free(boot);Free(home);
  if(DrvTextAttrGet('?')==0x0F && DrvTextAttrGet('[')==0x0F)mask|=16;
  if(Let2BlkDevType('A')==1 && Let2BlkDevType('B')==1 && Let2BlkDevType('C')==2 && Let2BlkDevType('L')==2 && Let2BlkDevType('M')==3 && Let2BlkDevType('P')==3 && Let2BlkDevType('Q')==4 && Let2BlkDevType('S')==4 && Let2BlkDevType('T')==5 && Let2BlkDevType('Z')==5 && Let2BlkDevType('?')==0)mask|=32;
  return mask;
}
