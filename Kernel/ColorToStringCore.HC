public U8 *Color2Str(U8 *buf,CColorROPU32 c)
{//$LK,"CColorROPU32",A="MN:CColorROPU32"$ with flags to $LK,"DCLighting",A="MN:DCLighting"$ str.
  *buf=0;
  if (c.c0.rop&ROPBF_TWO_SIDED)
    CatPrint(buf,"TWO|");
  if (c.c0.rop&ROPBF_HALF_RANGE_COLOR)
    CatPrint(buf,"HALF|");
  if (0<=c.c0.color<16)
    CatPrint(buf,DefineSub(c.c0.color,"ST_COLORS"));
  else if (c.c0.color==TRANSPARENT)
    CatPrint(buf,"TRANSPARENT");
  else
    CatPrint(buf,"INVALID");
  if (c&ROPF_DITHER) {
    CatPrint(buf,"/");
    if (c.c1.rop&ROPBF_TWO_SIDED)
      CatPrint(buf,"TWO|");
    if (c.c1.rop&ROPBF_HALF_RANGE_COLOR)
      CatPrint(buf,"HALF|");
    if (0<=c.c1.color<16)
      CatPrint(buf,DefineSub(c.c1.color,"ST_COLORS"));
    else if (c.c1.color==TRANSPARENT)
      CatPrint(buf,"TRANSPARENT");
    else
      CatPrint(buf,"INVALID");
  }
  return buf;
}
