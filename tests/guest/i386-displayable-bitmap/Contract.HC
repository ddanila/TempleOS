I64 JRContract(I64 unused)
{
  I64 mask=0,i;
  Bool ok=TRUE;
  for(i=0;i<31;i++)if(Bt(char_bmp_displayable,i))ok=FALSE;
  if(ok)mask|=1;
  if(Bt(char_bmp_displayable,31) && Bt(char_bmp_displayable,32) && Bt(char_bmp_displayable,126))mask|=2;
  if(!Bt(char_bmp_displayable,127))mask|=4;
  ok=TRUE;for(i=128;i<256;i++)if(!Bt(char_bmp_displayable,i))ok=FALSE;
  if(ok)mask|=8;
  ok=TRUE;for(i=256;i<512;i++)if(Bt(char_bmp_displayable,i))ok=FALSE;
  if(ok)mask|=16;
  ok=TRUE;for(i=0;i<512;i++)
    if(Bt(char_bmp_displayable,i)!=(i==31 || 32<=i<=126 || 128<=i<=255))ok=FALSE;
  if(ok)mask|=32;
  return mask;
}
