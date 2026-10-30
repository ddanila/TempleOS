public U0 GrPaletteGet(CBGR48 *bgr48)
{//16 colors
  I64 i;
  for (i=0;i<COLORS_NUM;i++)
    bgr48[i]=GrPaletteColorGet(i);
}

public U0 GrPaletteSet(CBGR48 *bgr48)
{//16 colors
  I64 i;
  for (i=0;i<COLORS_NUM;i++)
    GrPaletteColorSet(i,bgr48[i]);
}

