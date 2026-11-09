I64 TextProjectionContract(CI386Heap *heap)
{
  CI386Text direct,compact;
  U8 *a=I386HeapAlloc(heap,153600),*b=I386HeapAlloc(heap,153600);
  U8 *cells=I386HeapAlloc(heap,43200),*font=I386HeapAlloc(heap,2048);
  U8 *font2=I386HeapAlloc(heap,2048);
  I64 i;
  U8 ch;
  if(!a || !b || !cells || !font || !font2)return 1;
  //Even the space glyph has ink: freshly cleared pixels must stay background.
  for(i=0;i<2048;i++){font[i]=(i*73+19)^(i>>2);font2[i]=(i*37+11)^(i>>3);}
  if(!I386TextInit(&direct,a,font,2,13) || !I386TextCellsInit(&compact,cells,font,2,13))return 2;
  if(compact.planes || !I386TextMaterialize(&compact,b))return 3;
  for(i=0;i<153600;i++)if(a[i]!=b[i])return 4;
  compact.planes=0;
  for(i=0;i<6000;i++) {
    direct.foreground=compact.foreground=i/7&15;
    direct.background=compact.background=i/19&15;
    direct.underline=compact.underline=0;if(!(i%5))direct.underline=compact.underline=2;
    if(i%97<48)direct.font=compact.font=font;else direct.font=compact.font=font2;
    if(!(i%17))ch=8;else if(!(i%19))ch=13;else if(!(i%23))ch=10;
    else if(!(i%13))ch=9;else ch=32+i*11%224;
    I386TextPut(&direct,ch);I386TextPut(&compact,ch);
    if(direct.column!=compact.column || direct.row!=compact.row)return 5;
  }
  //Existing glyphs must not change when the borrowed font buffers change.
  for(i=0;i<2048;i++){font[i]^=255;font2[i]^=85;}
  if(!I386TextMaterialize(&compact,b))return 6;
  for(i=0;i<153600;i++)if(a[i]!=b[i])return 7;
  if(direct.column!=compact.column || direct.row!=compact.row ||
      direct.foreground!=compact.foreground || direct.background!=compact.background ||
      direct.underline!=compact.underline || direct.font!=compact.font)return 8;
  //Continue through both paths after materialization, then compare again.
  for(i=0;i<1000;i++) {
    ch=32+i*17%224;I386TextPut(&direct,ch);I386TextPut(&compact,ch);
  }
  for(i=0;i<153600;i++)if(a[i]!=b[i])return 9;
  if(I386TextCellsInit(&compact,0,font) || I386TextMaterialize(&compact,0))return 10;
  if(!I386HeapFree(heap,font2) || !I386HeapFree(heap,font) || !I386HeapFree(heap,cells) ||
      !I386HeapFree(heap,b) || !I386HeapFree(heap,a))return 11;
  return 0;
}
