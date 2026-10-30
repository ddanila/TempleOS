I64 palette_drive;
I64 PaletteContract()
{
  CBGR48 original[COLORS_NUM],values[COLORS_NUM],observed[COLORS_NUM],restored[COLORS_NUM],one;
  U8 *name,*check;I64 size,i,mask=0,flags=GetRFlags;
  GrPaletteGet(original);
  for(i=0;i<COLORS_NUM;i++) {
    values[i]=0;values[i].r=(i*4)<<10;values[i].g=(63-i*3)<<10;values[i].b=(i*7&63)<<10;
  }
  GrPaletteSet(values);GrPaletteGet(observed);
  for(i=0;i<COLORS_NUM;i++) {
    one=GrPaletteColorGet(i);
    if(one!=observed[i])break;
  }
  if(i==COLORS_NUM)mask|=1;
  name=MStrPrint("%c:/palette-values.BIN",palette_drive);
  FileWrite(name,observed,sizeof(observed));check=FileRead(name,&size);
  if(check && size==sizeof(observed) && !MemCmp(check,observed,size))mask|=2;
  Free(name);Free(check);
  GrPaletteSet(original);GrPaletteGet(restored);
  if(!MemCmp(original,restored,sizeof(original)))mask|=4;
  one=GrPaletteColorGet(0);GrPaletteColorSet(0,one);
  if(GrPaletteColorGet(0)==one)mask|=8;
  SetRFlags(flags&~512);GrPaletteColorSet(0,one);GrPaletteColorGet(0);
  if(!(GetRFlags&512))mask|=16;
  SetRFlags(flags|512);GrPaletteColorSet(0,one);GrPaletteColorGet(0);
  if(GetRFlags&512)mask|=32;
  SetRFlags(flags);
  return mask;
}
