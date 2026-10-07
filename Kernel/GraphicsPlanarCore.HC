U0 GraphicsPlanarSplitCore(U8 **planes,U8 *pixels)
{//Use the same low-bit-left logical planes as the existing VGA driver.
  I64 i;
  U64 pixels8,mask=0x0101010101010101,weights=0x0102040810204080;
  for(i=0;i<38400;i++) {
    pixels8=(pixels+i*8)(U64 *)[0];
    //Each byte contributes one bit; no partial sum can carry into another byte.
    planes[0][i]=((pixels8&mask)*weights)>>56;
    planes[1][i]=(((pixels8>>1)&mask)*weights)>>56;
    planes[2][i]=(((pixels8>>2)&mask)*weights)>>56;
    planes[3][i]=(((pixels8>>3)&mask)*weights)>>56;
  }
}
U0 GraphicsPlanarCore(U8 *planes,U8 *pixels)
{//Contiguous callers retain the same logical layout and byte order.
  U8 *split[4];
  I64 p;
  for(p=0;p<4;p++) split[p]=planes+p*38400;
  GraphicsPlanarSplitCore(split,pixels);
}
