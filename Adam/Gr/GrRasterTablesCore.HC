U0 GrRasterTablesInit()
{
  I64 i,j,k;
  k=0;
  for (i=0;i<256;i++)
    for (j=0;j<8;j++)
      if (Bt(&i,j))
	gr.to_8_bits(U8 *)[k++]=0xFF;
      else
	gr.to_8_bits(U8 *)[k++]=0x00;
  k=0;
  for (i=0;i<256;i++)
    for (j=0;j<8;j++)
      gr.to_8_colors(U8 *)[k++]=i;

}
